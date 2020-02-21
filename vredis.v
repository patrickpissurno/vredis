module vredis

import net
import strconv

pub struct ConnOpts {
	port int = 6379
	host string = '127.0.0.1'
}

pub struct Redis {
	socket net.Socket
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
	r.socket.close() or {}
}

pub fn (r Redis) set(key, value string) bool {
	message := 'SET $key "$value"\r\n'
	r.socket.write(message) or {
		return false
	}
	r.socket.read_line()
	return true
}

pub fn (r Redis) get(key string) ?string {
	message := 'GET $key\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	response := r.socket.read_line()
	len := parse_len(response)
	if len == -1 {
		return error('key not found')
	}
	return r.socket.read_line()[0..len]
}

pub fn (r Redis) del(key string) ?int {
	message := 'DEL $key\r\n'
	r.socket.write(message) or {
		return error(err)
	}
	response := r.socket.read_line()
	count := parse_len(response)
	return count
}

fn parse_len(res string) int {
	mut i := 0
	for ; i < res.len; i++ {
		if res[i] == `\r` {
			break
		}
	}
	slen := res[1..i]
	return strconv.atoi(slen)
}
