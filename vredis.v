module vredis

import net
import strconv

pub struct ConnOpts {
	port int=6379
	host string='127.0.0.1'
}

pub struct Redis {
	socket net.Socket
}

pub struct SetOpts {
	ex       int=-4
	px       int=-4
	nx       bool=false
	xx       bool=false
	keep_ttl bool=false
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

// https://github.com/v-community/learn_v_in_y_minutes/blob/master/learnv.v
// https://github.com/vlang/v/blob/master/vlib/net/socket_test.v
// https://redis.io/topics/protocol
pub fn connect(opts ConnOpts) ?Redis {
	socket := net.dial(opts.host, opts.port) or {
		return error(err)
	}
	return Redis{
		socket: socket
	}
}

pub fn (r Redis) disconnect() {
	r.socket.close() or { }
}

pub fn (r Redis) set(key, value string) bool {
	message := 'SET "$key" "$value"\r\n'
	r.socket.write(message) or {
		return false
	}
	res := r.socket.read_line()[0..3]
	match res {
		'+OK' {
			return true
		}
		else {
			return false
		}
	}
}

pub fn (r Redis) set_opts(key, value string, opts SetOpts) bool {
	ex := if opts.ex == -4 && opts.px == -4 { '' } else if opts.ex != -4 { ' EX $opts.ex' } else { ' PX $opts.px' }
	nx := if opts.nx == false && opts.xx == false { '' } else if opts.nx == true { ' NX' } else { ' XX' }
	keep_ttl := if opts.keep_ttl == false { '' } else { ' KEEPTTL' }
	message := 'SET "$key" "$value"$ex$nx$keep_ttl\r\n'
	r.socket.write(message) or {
		return false
	}
	res := r.socket.read_line()[0..3]
	match res {
		'+OK' {
			return true
		}
		else {
			return false
		}
	}
}

pub fn (r Redis) setex(key string, seconds int, value string) bool {
	return r.set_opts(key, value, SetOpts{
		ex: seconds
	})
}

pub fn (r Redis) psetex(key string, millis int, value string) bool {
	return r.set_opts(key, value, SetOpts{
		px: millis
	})
}

pub fn (r Redis) setnx(key string, value string) int {
	res := r.set_opts(key, value, SetOpts{
		nx: true
	})
	return if res == true { 1 } else { 0 }
}

pub fn (r Redis) incrby(key string, increment int) ?int {
	message := 'INCRBY "$key" $increment\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	count := parse_int(res)
	return count
}

pub fn (r Redis) incr(key string) ?int {
	res := r.incrby(key, 1) or {
		return error(err)
	}
	return res
}

pub fn (r Redis) decr(key string) ?int {
	res := r.incrby(key, -1) or {
		return error(err)
	}
	return res
}

pub fn (r Redis) decrby(key string, decrement int) ?int {
	res := r.incrby(key, -decrement) or {
		return error(err)
	}
	return res
}

pub fn (r Redis) incrbyfloat(key string, increment f64) ?f64 {
	message := 'INCRBYFLOAT "$key" $increment\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	rerr := parse_err(r.socket.read_line())
	if rerr != '' {
		return error(rerr)
	}
	res := r.socket.read_line()
	count := parse_float(res)
	return count
}

pub fn (r Redis) append(key string, value string) ?int {
	message := 'APPEND "$key" "$value"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	count := parse_int(r.socket.read_line())
	return count
}

pub fn (r Redis) setrange(key string, offset int, value string) ?int {
	message := 'SETRANGE "$key" $offset "$value"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	count := parse_int(r.socket.read_line())
	return count
}

pub fn (r Redis) expire(key string, seconds int) ?int {
	message := 'EXPIRE "$key" $seconds\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) pexpire(key string, millis int) ?int {
	message := 'PEXPIRE "$key" $millis\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) expireat(key string, timestamp int) ?int {
	message := 'EXPIREAT "$key" $timestamp\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) pexpireat(key string, millistimestamp i64) ?int {
	message := 'PEXPIREAT "$key" $millistimestamp\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) persist(key string) ?int {
	message := 'PERSIST "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) get(key string) ?string {
	message := 'GET "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	len := parse_int(res)
	if len == -1 {
		return error('key not found')
	}
	return r.socket.read_line()[0..len]
}

pub fn (r Redis) getset(key, value string) ?string {
	message := 'GETSET "$key" $value\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	len := parse_int(res)
	if len == -1 {
		return ''
	}
	return r.socket.read_line()[0..len]
}

pub fn (r Redis) getrange(key string, start, end int) ?string {
	message := 'GETRANGE "$key" $start $end\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	len := parse_int(res)
	if len == 0 {
		r.socket.read_line()
		return ''
	}
	return r.socket.read_line()[0..len]
}

pub fn (r Redis) randomkey() ?string {
	message := 'RANDOMKEY\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	len := parse_int(res)
	if len == -1 {
		return error('database is empty')
	}
	return r.socket.read_line()[0..len]
}

pub fn (r Redis) strlen(key string) ?int {
	message := 'STRLEN "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) ttl(key string) ?int {
	message := 'TTL "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) pttl(key string) ?int {
	message := 'PTTL "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) exists(key string) ?int {
	message := 'EXISTS "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) type_of(key string) ?KeyType {
	message := 'TYPE "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	return match res[1..res.len - 2] {
		'none'{
			KeyType.t_none
		}
		'string'{
			KeyType.t_string
		}
		'list'{
			KeyType.t_list
		}
		'set'{
			KeyType.t_set
		}
		'zset'{
			KeyType.t_zset
		}
		'hash'{
			KeyType.t_hash
		}
		'stream'{
			KeyType.t_stream
		}
		else {
			.t_unknown}
	}
}

pub fn (r Redis) del(key string) ?int {
	message := 'DEL "$key"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	count := parse_int(res)
	return count
}

pub fn (r Redis) rename(key, newkey string) bool {
	message := 'RENAME "$key" "$newkey"\r\n'
	r.socket.write(message) or {
		return false
	}
	res := r.socket.read_line()[0..3]
	match res {
		'+OK' {
			return true
		}
		else {
			return false
		}
	}
}

pub fn (r Redis) renamenx(key, newkey string) ?int {
	message := 'RENAMENX "$key" "$newkey"\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	res := r.socket.read_line()
	rerr := parse_err(res)
	if rerr != '' {
		return error(rerr)
	}
	count := parse_int(res)
	return count
}

pub fn (r Redis) flushall() bool {
	message := 'FLUSHALL\r\n'
	r.socket.write(message) or {
		return false
	}
	res := r.socket.read_line()[0..3]
	match res {
		'+OK' {
			return true
		}
		else {
			return false
		}
	}
}

fn parse_int(res string) int {
	sval := res[1..res.len - 2]
	return strconv.atoi(sval)
}

fn parse_float(res string) f64 {
	return strconv.atof64(res)
}

fn parse_err(res string) string {
	if res[0..4] == '-ERR' {
		return res[5..res.len - 2]
	}
	return ''
}
