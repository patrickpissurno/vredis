module vredis

fn setup() Redis {
	redis := connect(ConnOpts{}) or {
		panic(err)
	}
	return redis
}

fn cleanup(mut redis Redis) {
	redis.flushall()
	redis.disconnect()
}

fn test_set() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 0', '123') == true
	assert redis.set('test 0', '456') == true
}

fn test_set_opts() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set_opts('test 5', '123', SetOpts{
		ex: 2
	}) == true
	assert redis.set_opts('test 5', '456', SetOpts{
		px: 2000
		xx: true
	}) == true
	assert redis.set_opts('test 5', '789', SetOpts{
		px: 1000
		nx: true
	}) == false
	// assert redis.set_opts('test 5', '012', SetOpts{ keep_ttl: true }) == true //disabled because I don't have redis >= 6 to test it
}

fn test_setex() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.setex('test 6', 2, '123') == true
}

fn test_psetex() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.psetex('test 7', 2000, '123') == true
}

fn test_setnx() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.setnx('test 8', '123') == 1
	assert redis.setnx('test 8', '456') == 0
}

fn test_incrby() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 20', '100') == true
	r1 := redis.incrby('test 20', 4) or {
		assert false
		return
	}
	assert r1 == 104
	r2 := redis.incrby('test 21', 2) or {
		assert false
		return
	}
	assert r2 == 2
	assert redis.set('test 23', 'nan') == true
	redis.incrby('test 23', 1) or {
		assert true
		return
	}
	assert false
}

fn test_incr() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 24', '100') == true
	r1 := redis.incr('test 24') or {
		assert false
		return
	}
	assert r1 == 101
	r2 := redis.incr('test 25') or {
		assert false
		return
	}
	assert r2 == 1
	assert redis.set('test 26', 'nan') == true
	redis.incr('test 26') or {
		assert true
		return
	}
	assert false
}

fn test_decr() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 27', '100') == true
	r1 := redis.decr('test 27') or {
		assert false
		return
	}
	assert r1 == 99
	r2 := redis.decr('test 28') or {
		assert false
		return
	}
	assert r2 == -1
	assert redis.set('test 29', 'nan') == true
	redis.decr('test 29') or {
		assert true
		return
	}
	assert false
}

fn test_decrby() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 30', '100') == true
	r1 := redis.decrby('test 30', 4) or {
		assert false
		return
	}
	assert r1 == 96
	r2 := redis.decrby('test 31', 2) or {
		assert false
		return
	}
	assert r2 == -2
	assert redis.set('test 32', 'nan') == true
	redis.decrby('test 32', 1) or {
		assert true
		return
	}
	assert false
}

fn test_incrbyfloat() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 33', '3.1415') == true
	r1 := redis.incrbyfloat('test 33', 3.1415) or {
		assert false
		return
	}
	assert r1 == 6.283
	r2 := redis.incrbyfloat('test 34', 3.14) or {
		assert false
		return
	}
	assert r2 == 3.14
	r3 := redis.incrbyfloat('test 34', -3.14) or {
		assert false
		return
	}
	assert r3 == 0
	assert redis.set('test 35', 'nan') == true
	redis.incrbyfloat('test 35', 1.5) or {
		assert true
		return
	}
	assert false
}

fn test_append() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 48', 'bac') == true
	r1 := redis.append('test 48', 'on') or {
		assert false
		return
	}
	assert r1 == 5
	r2 := redis.get('test 48') or {
		assert false
		return
	}
	assert r2 == 'bacon'
}

fn test_lpush() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r := redis.lpush('test 53', 'item 1') or {
		assert false
		return
	}
	assert r == 1
}

fn test_rpush() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r := redis.rpush('test 59', 'item 1') or {
		assert false
		return
	}
	assert r == 1
}

fn test_setrange() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.setrange('test 52', 0, 'bac') or {
		assert false
		return
	}
	assert r1 == 3
	r2 := redis.setrange('test 52', 3, 'on') or {
		assert false
		return
	}
	assert r2 == 5
}

fn test_expire() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.expire('test 10', 2) or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.set('test 10', '123') == true
	r2 := redis.expire('test 10', 2) or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_pexpire() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.pexpire('test 11', 200) or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.set('test 11', '123') == true
	r2 := redis.pexpire('test 11', 200) or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_expireat() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.expireat('test 12', 1293840000) or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.set('test 12', '123') == true
	r2 := redis.expireat('test 12', 1293840000) or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_pexpireat() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.pexpireat('test 13', 1555555555005) or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.set('test 13', '123') == true
	r2 := redis.pexpireat('test 13', 1555555555005) or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_persist() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.persist('test 46') or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.setex('test 46', 2, '123') == true
	r2 := redis.persist('test 46') or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_get() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 2', '123') == true
	r := redis.get('test 2') or {
		assert false
		return
	}
	assert r == '123'
	assert helper_get_key_not_found(mut redis, 'test 3') == true
}

fn test_getset() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.getset('test 36', '10') or {
		assert false
		return
	}
	assert r1 == ''
	r2 := redis.getset('test 36', '15') or {
		assert false
		return
	}
	assert r2 == '10'
	r3 := redis.get('test 36') or {
		assert false
		return
	}
	assert r3 == '15'
}

fn test_getrange() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 50', 'community') == true
	r1 := redis.getrange('test 50', 4, -1) or {
		assert false
		return
	}
	assert r1 == 'unity'
	r2 := redis.getrange('test 51', 0, -1) or {
		assert false
		return
	}
	assert r2 == ''
}

fn test_randomkey() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert helper_randomkey_database_empty(mut redis) == true
	assert redis.set('test 47', '123') == true
	r2 := redis.randomkey() or {
		assert false
		return
	}
	assert r2 == 'test 47'
	assert helper_get_key_not_found(mut redis, 'test 3') == true
}

fn test_strlen() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 49', 'bacon') == true
	r1 := redis.strlen('test 49') or {
		assert false
		return
	}
	assert r1 == 5
	r2 := redis.strlen('test 50') or {
		assert false
		return
	}
	assert r2 == 0
}

fn test_lpop() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	redis.lpush('test 54', '123') or {
		assert false
		return
	}
	r1 := redis.lpop('test 54') or {
		assert false
		return
	}
	assert r1 == '123'
	assert helper_lpop_key_not_found(mut redis, 'test 55') == true
}

fn test_rpop() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	redis.lpush('test 60', '123') or {
		assert false
		return
	}
	r1 := redis.rpop('test 60') or {
		assert false
		return
	}
	assert r1 == '123'
	assert helper_rpop_key_not_found(mut redis, 'test 61') == true
}

fn test_llen() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.lpush('test 56', '123') or {
		assert false
		return
	}
	r2 := redis.llen('test 56') or {
		assert false
		return
	}
	assert r2 == r1
	r3 := redis.llen('test 57') or {
		assert false
		return
	}
	assert r3 == 0
	assert redis.set('test 58', 'not a list') == true
	redis.llen('test 58') or {
		assert true
		return
	}
	assert false
}

fn test_ttl() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.setex('test 14', 15, '123') == true
	r1 := redis.ttl('test 14') or {
		assert false
		return
	}
	assert r1 == 15
	assert redis.set('test 15', '123') == true
	r2 := redis.ttl('test 15') or {
		assert false
		return
	}
	assert r2 == -1
	r3 := redis.ttl('test 16') or {
		assert false
		return
	}
	assert r3 == -2
}

fn test_pttl() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.psetex('test 17', 1500, '123') == true
	r1 := redis.pttl('test 17') or {
		assert false
		return
	}
	assert r1 >= 1490 && r1 <= 1500
	assert redis.set('test 18', '123') == true
	r2 := redis.pttl('test 18') or {
		assert false
		return
	}
	assert r2 == -1
	r3 := redis.pttl('test 19') or {
		assert false
		return
	}
	assert r3 == -2
}

fn test_exists() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.exists('test 37') or {
		assert false
		return
	}
	assert r1 == 0
	assert redis.set('test 38', '123') == true
	r2 := redis.exists('test 38') or {
		assert false
		return
	}
	assert r2 == 1
}

fn test_type_of() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	r1 := redis.type_of('test 39') or {
		assert false
		return
	}
	assert r1 == .t_none
	assert redis.set('test 40', '123') == true
	r2 := redis.type_of('test 40') or {
		assert false
		return
	}
	assert r2 == .t_string
}

fn test_del() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 4', '123') == true
	c := redis.del('test 4') or {
		assert false
		return
	}
	assert c == 1
	assert helper_get_key_not_found(mut redis, 'test 4') == true
}

fn test_rename() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.rename('test 41', 'test 42') == false
	assert redis.set('test 41', 'will be 42') == true
	assert redis.rename('test 41', 'test 42') == true
	r := redis.get('test 42') or {
		assert false
		return
	}
	assert r == 'will be 42'
}

fn test_renamenx() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 45', '123') == true
	assert helper_renamenx_err_helper(mut redis, 'test 43', 'test 44') == 'no such key'
	assert redis.set('test 43', 'will be 44') == true
	r1 := redis.renamenx('test 43', 'test 44') or {
		assert false
		return
	}
	assert r1 == 1
	r2 := redis.get('test 44') or {
		assert false
		return
	}
	assert r2 == 'will be 44'
	r3 := redis.renamenx('test 44', 'test 45') or {
		assert false
		return
	}
	assert r3 == 0
}

fn test_flushall() {
	mut redis := setup()
	defer {
		cleanup(mut redis)
	}
	assert redis.set('test 9', '123') == true
	assert redis.flushall() == true
	assert helper_get_key_not_found(mut redis, 'test 9') == true
}

fn helper_get_key_not_found(mut redis Redis, key string) bool {
	redis.get(key) or {
		if err.msg == 'key not found' {
			return true
		}
		else {
			return false
		}
	}
	return false
}

fn helper_randomkey_database_empty(mut redis Redis) bool {
	redis.randomkey() or {
		if err.msg == 'database is empty' {
			return true
		}
		else {
			return false
		}
	}
	return false
}

fn helper_renamenx_err_helper(mut redis Redis, key string, newkey string) string {
	redis.renamenx(key, newkey) or {
		return err.msg
	}
	return ''
}

fn helper_lpop_key_not_found(mut redis Redis, key string) bool {
	redis.lpop(key) or {
		if err.msg == 'key not found' {
			return true
		}
		else {
			return false
		}
	}
	return false
}

fn helper_rpop_key_not_found(mut redis Redis, key string) bool {
	redis.rpop(key) or {
		if err.msg == 'key not found' {
			return true
		}
		else {
			return false
		}
	}
	return false
}
