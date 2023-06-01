module redis

import net
import strconv
import runtime
import sync

pub struct ConnOpts {
	port int    = 6379
	host string = '127.0.0.1'
}

pub struct Redis {
mut:
	socket net.TcpConn
}

pub struct SetOpts {
	ex       int = -4
	px       int = -4
	nx       bool
	xx       bool
	keep_ttl bool
}

pub enum KeyType {
	t_none
	t_string
	t_list
	t_set
	t_zset
	t_hash
	t_stream
	t_unknown
}

/*
* Connection pool
 * Begin
*/

pub struct RedisPool {
	opts PoolOpts
mut:
	conns              []Redis
	conns_availability []bool
	conns_available    int
	mutex              sync.Mutex
}

pub struct PoolOpts {
	conn_opts ConnOpts
	min_conns int
	max_conns int
	db        int
	username  string
	password  string
}

pub fn new_pool(opts PoolOpts) !RedisPool {
	if opts.min_conns < 0 {
		return error('PoolOpts.min_conns must be > 0')
	}

	mut start_conns := opts.min_conns
	if start_conns == 0 {
		start_conns = runtime.nr_cpus()
	}

	mut redis_pool := []Redis{}
	mut conns_availability := []bool{}
	mutex := sync.new_mutex()
	for i := 0; i < start_conns; i++ {
		conn := connect(opts.conn_opts) or { return err }
		if opts.password != '' {
			conn.auth(opts.username, opts.password)
		}
		if opts.db != 0 {
			conn.select_db(opts.db)
		}
		redis_pool << conn
		conns_availability << true
	}

	return RedisPool{
		opts: opts
		conns: redis_pool
		conns_availability: conns_availability
		conns_available: start_conns
		mutex: mutex
	}
}

pub fn (mut pool RedisPool) borrow() !&Redis {
	// Borrow a connection from the pool
	pool.mutex.@lock()
	if pool.conns_available > 0 {
		for i := 0; i < pool.conns.len; i++ {
			if pool.conns_availability[i] {
				pool.conns_availability[i] = false
				pool.conns_available -= 1
				pool.mutex.unlock()
				return &pool.conns[i]
			}
		}
	}

	if pool.conns.len < pool.opts.max_conns {
		conn := connect(pool.opts.conn_opts) or { return err }
		if pool.opts.password != '' {
			conn.auth(pool.opts.username, pool.opts.password)
		}
		if pool.opts.db != 0 {
			conn.select_db(pool.opts.db)
		}
		pool.conns << conn
		pool.conns_availability << true
		pool.conns_available += 1
		pool.mutex.unlock()
		return pool.borrow()
	}

	if pool.conns.len == pool.opts.max_conns {
		// TODO wait for available conn
	}
	return error('Failed to borrow a connection from the pool')
}

pub fn (mut pool RedisPool) release(redis_conn &Redis) ! {
	pool.mutex.@lock()
	for i := 0; i < pool.conns.len; i++ {
		if &pool.conns[i] == &redis_conn {
			pool.conns_availability[i] = true
			pool.conns_available += 1
			pool.mutex.unlock()
			return
		}
	}
	return error('Connection could not be freed')
	// TODO idle connection life
}

pub fn (mut pool RedisPool) disconnect() {
	for i := 0; i < pool.conns.len; i++ {
		pool.conns[i].disconnect()
	}
}

/*
* Connection pool
 * End
*/

fn (mut r Redis) redis_transaction(message string) !string {
	r.socket.write_string(message)!
	return r.socket.read_line()
}

// https://github.com/v-community/learn_v_in_y_minutes/blob/master/learnv.v
// https://github.com/vlang/v/blob/master/vlib/net/socket_test.v
// https://redis.io/topics/protocol
pub fn connect(opts ConnOpts) !Redis {
	mut socket := net.dial_tcp('${opts.host}:${opts.port}')!
	return Redis{
		socket: socket
	}
}

pub fn (mut r Redis) disconnect() {
	r.socket.close() or {}
}

pub fn (mut r Redis) auth(username string, password string) bool {
	res := r.redis_transaction('AUTH ${username} "${password}"\r\n') or { return false }
	return res.starts_with('+OK')
}

pub fn (mut r Redis) set(key string, value string) bool {
	res := r.redis_transaction('SET "${key}" "${value}"\r\n') or { return false }
	return res.starts_with('+OK')
}

pub fn (mut r Redis) set_opts(key string, value string, opts SetOpts) bool {
	ex := if opts.ex == -4 && opts.px == -4 {
		''
	} else if opts.ex != -4 {
		' EX ${opts.ex}'
	} else {
		' PX ${opts.px}'
	}
	nx := if opts.nx == false && opts.xx == false {
		''
	} else if opts.nx == true {
		' NX'
	} else {
		' XX'
	}
	keep_ttl := if opts.keep_ttl == false { '' } else { ' KEEPTTL' }
	res := r.redis_transaction('SET "${key}" "${value}"${ex}${nx}${keep_ttl}\r\n') or {
		return false
	}
	return res.starts_with('+OK')
}

pub fn (mut r Redis) setex(key string, seconds int, value string) bool {
	return r.set_opts(key, value, SetOpts{
		ex: seconds
	})
}

pub fn (mut r Redis) psetex(key string, millis int, value string) bool {
	return r.set_opts(key, value, SetOpts{
		px: millis
	})
}

pub fn (mut r Redis) setnx(key string, value string) int {
	res := r.set_opts(key, value, SetOpts{
		nx: true
	})
	return if res == true { 1 } else { 0 }
}

pub fn (mut r Redis) incrby(key string, increment int) !int {
	res := r.redis_transaction('INCRBY "${key}" ${increment}\r\n')!
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	return parse_int(res)
}

pub fn (mut r Redis) incr(key string) !int {
	res := r.incrby(key, 1)!
	return res
}

pub fn (mut r Redis) decr(key string) !int {
	res := r.incrby(key, -1)!
	return res
}

pub fn (mut r Redis) decrby(key string, decrement int) !int {
	res := r.incrby(key, -decrement)!
	return res
}

pub fn (mut r Redis) incrbyfloat(key string, increment f64) !f64 {
	mut res := r.redis_transaction('INCRBYFLOAT "${key}" ${increment}\r\n')!
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	res = r.socket.read_line()
	return parse_float(res)
}

pub fn (mut r Redis) append(key string, value string) !int {
	res := r.redis_transaction('APPEND "${key}" "${value}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) setrange(key string, offset int, value string) !int {
	res := r.redis_transaction('SETRANGE "${key}" ${offset} "${value}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) lpush(key string, element string) !int {
	res := r.redis_transaction('LPUSH "${key}" "${element}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) rpush(key string, element string) !int {
	res := r.redis_transaction('RPUSH "${key}" "${element}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) expire(key string, seconds int) !int {
	res := r.redis_transaction('EXPIRE "${key}" ${seconds}\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) pexpire(key string, millis int) !int {
	res := r.redis_transaction('PEXPIRE "${key}" ${millis}\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) expireat(key string, timestamp int) !int {
	res := r.redis_transaction('EXPIREAT "${key}" ${timestamp}\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) pexpireat(key string, millistimestamp i64) !int {
	res := r.redis_transaction('PEXPIREAT "${key}" ${millistimestamp}\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) persist(key string) !int {
	res := r.redis_transaction('PERSIST "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) get(key string) !string {
	res := r.redis_transaction('GET "${key}"\r\n')!
	len := parse_int(res)
	if len == -1 {
		return error('key not found')
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) getset(key string, value string) !string {
	res := r.redis_transaction('GETSET "${key}" ${value}\r\n')!
	len := parse_int(res)
	if len == -1 {
		return ''
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) getrange(key string, start int, end int) !string {
	res := r.redis_transaction('GETRANGE "${key}" ${start} ${end}\r\n')!
	len := parse_int(res)
	if len == 0 {
		r.socket.read_line()
		return ''
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) randomkey() !string {
	res := r.redis_transaction('RANDOMKEY\r\n')!
	len := parse_int(res)
	if len == -1 {
		return error('database is empty')
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) strlen(key string) !int {
	res := r.redis_transaction('STRLEN "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) lpop(key string) !string {
	res := r.redis_transaction('LPOP "${key}"\r\n')!
	len := parse_int(res)
	if len == -1 {
		return error('key not found')
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) rpop(key string) !string {
	res := r.redis_transaction('RPOP "${key}"\r\n')!
	len := parse_int(res)
	if len == -1 {
		return error('key not found')
	}
	return r.socket.read_line()[0..len]
}

pub fn (mut r Redis) llen(key string) !int {
	res := r.redis_transaction('LLEN "${key}"\r\n')!
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	return parse_int(res)
}

pub fn (mut r Redis) ttl(key string) !int {
	res := r.redis_transaction('TTL "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) pttl(key string) !int {
	res := r.redis_transaction('PTTL "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) exists(key string) !int {
	res := r.redis_transaction('EXISTS "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) type_of(key string) !KeyType {
	res := r.redis_transaction('TYPE "${key}"\r\n')!
	if res.len > 6 {
		return match res#[1..res.len - 2] {
			'none' {
				KeyType.t_none
			}
			'string' {
				KeyType.t_string
			}
			'list' {
				KeyType.t_list
			}
			'set' {
				KeyType.t_set
			}
			'zset' {
				KeyType.t_zset
			}
			'hash' {
				KeyType.t_hash
			}
			'stream' {
				KeyType.t_stream
			}
			else {
				KeyType.t_unknown
			}
		}
	} else {
		return KeyType.t_unknown
	}
}

pub fn (mut r Redis) del(key string) !int {
	res := r.redis_transaction('DEL "${key}"\r\n')!
	return parse_int(res)
}

pub fn (mut r Redis) rename(key string, newkey string) bool {
	res := r.redis_transaction('RENAME "${key}" "${newkey}"\r\n') or { return false }
	return res.starts_with('+OK')
}

pub fn (mut r Redis) renamenx(key string, newkey string) !int {
	res := r.redis_transaction('RENAMENX "${key}" "${newkey}"\r\n')!
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	return parse_int(res)
}

pub fn (mut r Redis) flushall() bool {
	res := r.redis_transaction('FLUSHALL\r\n') or { return false }
	return res.starts_with('+OK')
}

fn parse_int(res string) int {
	return if res.len > 1 { res[1..].int() } else { 0 }
}

fn parse_float(res string) f64 {
	return strconv.atof64(res) or { 0 }
}

fn parse_err(res string) string {
	if res.len >= 5 && res.starts_with('-ERR') {
		return res[5..res.len - 2]
	} else if res.len >= 11 && res[0..10] == '-WRONGTYPE' {
		return res[11..res.len - 2]
	}
	return ''
}

pub fn (mut r Redis) ping() bool {
	res := r.redis_transaction('PING\r\n') or { return false }
	return res.starts_with('+PONG')
}

// select_db executes a select statement. Note: `select` is a reserved keyword in V.
pub fn (mut r Redis) select_db(db_number int) bool {
	res := r.redis_transaction('SELECT ${db_number}\r\n') or { return false }
	return res.starts_with('+OK')
}
