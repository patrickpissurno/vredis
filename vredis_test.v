import vredis

fn setup() vredis.Redis {
	redis := vredis.connect(vredis.ConnOpts{}) or {
		panic(err)
	}
	return redis
}

fn cleanup(redis vredis.Redis) {
	redis.disconnect()
}

fn test_set() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test', '123') == true
	assert redis.set('test', '456') == true
}

fn test_get() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test2', '123') == true
	r := redis.get('test2') or {
		assert false
		return
	}
	assert r == '123'
	assert _key_not_found(redis, 'test3') == true
}

fn test_del() {
	redis := setup()
	defer {
		cleanup(redis)
	}
	assert redis.set('test4', '123') == true
	c := redis.del('test4') or {
		assert false
		return
	}
	assert c == 1
	assert _key_not_found(redis, 'test4') == true
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
