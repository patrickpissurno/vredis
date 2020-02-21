import vredis

fn setup() vredis.Redis {
	redis := vredis.connect(vredis.ConnOpts{}) or {
		panic(err)
	}
	return redis
}

fn cleanup(redis vredis.Redis) {
	redis.flushall()
	redis.disconnect()
}

fn test_set() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test 0', '123') == true
	assert redis.set('test 0', '456') == true
}

fn test_set_opts() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set_opts('test 5', '123', vredis.SetOpts{
		ex: 2
	}) == true
	assert redis.set_opts('test 5', '456', vredis.SetOpts{
		px: 2000
		xx: true
	}) == true
	assert redis.set_opts('test 5', '789', vredis.SetOpts{
		px: 1000
		nx: true
	}) == false
	// assert redis.set_opts('test 5', '012', vredis.SetOpts{ keep_ttl: true }) == true //disabled because I don't have redis >= 6 to test it
}

fn test_setex() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.setex('test 6', 2, '123') == true
}

fn test_psetex() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.psetex('test 7', 2000, '123') == true
}

fn test_setnx() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.setnx('test 8', '123') == 1
	assert redis.setnx('test 8', '456') == 0
}

fn test_expire() {
	redis := setup()
	defer {
		cleanup(redis)
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
	redis := setup()
	defer {
		cleanup(redis)
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
	redis := setup()
	defer {
		cleanup(redis)
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
	redis := setup()
	defer {
		cleanup(redis)
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

fn test_get() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test 2', '123') == true
	r := redis.get('test 2') or {
		assert false
		return
	}
	assert r == '123'
	assert _key_not_found(redis, 'test 3') == true
}

fn test_ttl() {
	redis := setup()
	defer {
		cleanup(redis)
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
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.psetex('test 17', 1500, '123') == true
	r1 := redis.pttl('test 17') or {
		assert false
		return
	}
	assert r1 == 1500
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

fn test_del() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test 4', '123') == true
	c := redis.del('test 4') or {
		assert false
		return
	}
	assert c == 1
	assert _key_not_found(redis, 'test 4') == true
}

fn test_flushall() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test 9', '123') == true
	assert redis.flushall() == true
	assert _key_not_found(redis, 'test 9') == true
}

fn _key_not_found(redis vredis.Redis, key string) bool {
	redis.get(key) or {
		if (err == 'key not found') {
			return true
		}
		else {
			return false
		}
	}
	return false
}
