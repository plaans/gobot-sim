const PROTO_VERSION = 2

#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2020, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"
const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PoolByteArray:
		var varint : PoolByteArray = PoolByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PoolByteArray:
		var bytes : PoolByteArray = PoolByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PoolByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PoolByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PoolByteArray, index : int) -> PoolByteArray:
		var result : PoolByteArray = PoolByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PoolByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PoolByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PoolByteArray) -> PoolByteArray:
		var result : PoolByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PoolByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PoolByteArray = pack_type_tag(type, field.tag)
		var data : PoolByteArray = PoolByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PoolByteArray = v.to_bytes()
						#if obj != null && obj.size() > 0:
						#	data.append_array(pack_length_delimeted(type, field.tag, obj))
						#else:
						#	data = PoolByteArray()
						#	return data
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PoolByteArray = field.value.to_utf8()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PoolByteArray = field.value.to_bytes()
					#if obj != null && obj.size() > 0:
					#	data.append_array(obj)
					#	return pack_length_delimeted(type, field.tag, data)
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PoolByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call_func()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PoolByteArray = PoolByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PoolByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PoolByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PoolByteArray = PoolByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PoolByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += String(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + String(value)
		else:
			result += String(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(String(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) && data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class Command:
	func _init():
		var service
		
		_command = PBField.new("command", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = _command
		data[_command.tag] = service
		
		_dir = PBField.new("dir", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _dir
		data[_dir.tag] = service
		
		_speed = PBField.new("speed", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _speed
		data[_speed.tag] = service
		
		_time = PBField.new("time", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
		service = PBServiceField.new()
		service.field = _time
		data[_time.tag] = service
		
	var data = {}
	
	var _command: PBField
	func get_command():
		return _command.value
	func clear_command() -> void:
		_command.value = DEFAULT_VALUES_2[PB_DATA_TYPE.ENUM]
	func set_command(value) -> void:
		_command.value = value
	
	var _dir: PBField
	func get_dir() -> float:
		return _dir.value
	func clear_dir() -> void:
		_dir.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
	func set_dir(value : float) -> void:
		_dir.value = value
	
	var _speed: PBField
	func get_speed() -> float:
		return _speed.value
	func clear_speed() -> void:
		_speed.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
	func set_speed(value : float) -> void:
		_speed.value = value
	
	var _time: PBField
	func get_time() -> float:
		return _time.value
	func clear_time() -> void:
		_time.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
	func set_time(value : float) -> void:
		_time.value = value
	
	enum Command_types {
		GOTO = 0,
		PICKUP = 1
	}
	
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class State:
	func _init():
		var service
		
		_robots = PBField.new("robots", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, false, [])
		service = PBServiceField.new()
		service.field = _robots
		service.func_ref = funcref(self, "add_robots")
		data[_robots.tag] = service
		
		_packages = PBField.new("packages", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, false, [])
		service = PBServiceField.new()
		service.field = _packages
		service.func_ref = funcref(self, "add_packages")
		data[_packages.tag] = service
		
	var data = {}
	
	var _robots: PBField
	func get_robots() -> Array:
		return _robots.value
	func clear_robots() -> void:
		_robots.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
	func add_robots() -> State.Robot:
		var element = State.Robot.new()
		_robots.value.append(element)
		return element
	
	var _packages: PBField
	func get_packages() -> Array:
		return _packages.value
	func clear_packages() -> void:
		_packages.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
	func add_packages() -> State.Package:
		var element = State.Package.new()
		_packages.value.append(element)
		return element
	
	class Robot:
		func _init():
			var service
			
			_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _x
			data[_x.tag] = service
			
			_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _y
			data[_y.tag] = service
			
			_battery = PBField.new("battery", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _battery
			data[_battery.tag] = service
			
			_is_moving = PBField.new("is_moving", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, false, DEFAULT_VALUES_2[PB_DATA_TYPE.BOOL])
			service = PBServiceField.new()
			service.field = _is_moving
			data[_is_moving.tag] = service
			
		var data = {}
		
		var _x: PBField
		func get_x() -> float:
			return _x.value
		func clear_x() -> void:
			_x.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_x(value : float) -> void:
			_x.value = value
		
		var _y: PBField
		func get_y() -> float:
			return _y.value
		func clear_y() -> void:
			_y.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_y(value : float) -> void:
			_y.value = value
		
		var _battery: PBField
		func get_battery() -> float:
			return _battery.value
		func clear_battery() -> void:
			_battery.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_battery(value : float) -> void:
			_battery.value = value
		
		var _is_moving: PBField
		func get_is_moving() -> bool:
			return _is_moving.value
		func clear_is_moving() -> void:
			_is_moving.value = DEFAULT_VALUES_2[PB_DATA_TYPE.BOOL]
		func set_is_moving(value : bool) -> void:
			_is_moving.value = value
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Package:
		func _init():
			var service
			
			_location = PBField.new("location", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE])
			service = PBServiceField.new()
			service.field = _location
			service.func_ref = funcref(self, "new_location")
			data[_location.tag] = service
			
			_processes_list = PBField.new("processes_list", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, false, [])
			service = PBServiceField.new()
			service.field = _processes_list
			service.func_ref = funcref(self, "add_processes_list")
			data[_processes_list.tag] = service
			
			_delivery_time = PBField.new("delivery_time", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _delivery_time
			data[_delivery_time.tag] = service
			
		var data = {}
		
		var _location: PBField
		func get_location() -> State.Location:
			return _location.value
		func clear_location() -> void:
			_location.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
		func new_location() -> State.Location:
			_location.value = State.Location.new()
			return _location.value
		
		var _processes_list: PBField
		func get_processes_list() -> Array:
			return _processes_list.value
		func clear_processes_list() -> void:
			_processes_list.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
		func add_processes_list() -> State.Process:
			var element = State.Process.new()
			_processes_list.value.append(element)
			return element
		
		var _delivery_time: PBField
		func get_delivery_time() -> float:
			return _delivery_time.value
		func clear_delivery_time() -> void:
			_delivery_time.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_delivery_time(value : float) -> void:
			_delivery_time.value = value
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Location:
		func _init():
			var service
			
			_location_type = PBField.new("location_type", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.ENUM])
			service = PBServiceField.new()
			service.field = _location_type
			data[_location_type.tag] = service
			
			_parent_id = PBField.new("parent_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.INT32])
			service = PBServiceField.new()
			service.field = _parent_id
			data[_parent_id.tag] = service
			
		var data = {}
		
		var _location_type: PBField
		func get_location_type():
			return _location_type.value
		func clear_location_type() -> void:
			_location_type.value = DEFAULT_VALUES_2[PB_DATA_TYPE.ENUM]
		func set_location_type(value) -> void:
			_location_type.value = value
		
		var _parent_id: PBField
		func get_parent_id() -> int:
			return _parent_id.value
		func clear_parent_id() -> void:
			_parent_id.value = DEFAULT_VALUES_2[PB_DATA_TYPE.INT32]
		func set_parent_id(value : int) -> void:
			_parent_id.value = value
		
		enum Location_Type {
			ROBOT = 0,
			ARRIVAL = 1,
			MACHINE_INPUT = 2,
			MACHINE_INSIDE = 3,
			MACHINE_OUTPUT = 4
		}
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Process:
		func _init():
			var service
			
			_process_id = PBField.new("process_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.INT32])
			service = PBServiceField.new()
			service.field = _process_id
			data[_process_id.tag] = service
			
			_process_duration = PBField.new("process_duration", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _process_duration
			data[_process_duration.tag] = service
			
		var data = {}
		
		var _process_id: PBField
		func get_process_id() -> int:
			return _process_id.value
		func clear_process_id() -> void:
			_process_id.value = DEFAULT_VALUES_2[PB_DATA_TYPE.INT32]
		func set_process_id(value : int) -> void:
			_process_id.value = value
		
		var _process_duration: PBField
		func get_process_duration() -> float:
			return _process_duration.value
		func clear_process_duration() -> void:
			_process_duration.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_process_duration(value : float) -> void:
			_process_duration.value = value
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Environment_Description:
	func _init():
		var service
		
		_machines = PBField.new("machines", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, false, [])
		service = PBServiceField.new()
		service.field = _machines
		service.func_ref = funcref(self, "add_machines")
		data[_machines.tag] = service
		
		_arrival_area = PBField.new("arrival_area", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _arrival_area
		service.func_ref = funcref(self, "new_arrival_area")
		data[_arrival_area.tag] = service
		
		_delivery_area = PBField.new("delivery_area", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = _delivery_area
		service.func_ref = funcref(self, "new_delivery_area")
		data[_delivery_area.tag] = service
		
	var data = {}
	
	var _machines: PBField
	func get_machines() -> Array:
		return _machines.value
	func clear_machines() -> void:
		_machines.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
	func add_machines() -> Environment_Description.Machine:
		var element = Environment_Description.Machine.new()
		_machines.value.append(element)
		return element
	
	var _arrival_area: PBField
	func get_arrival_area() -> Environment_Description.Area_Description:
		return _arrival_area.value
	func clear_arrival_area() -> void:
		_arrival_area.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
	func new_arrival_area() -> Environment_Description.Area_Description:
		_arrival_area.value = Environment_Description.Area_Description.new()
		return _arrival_area.value
	
	var _delivery_area: PBField
	func get_delivery_area() -> Environment_Description.Area_Description:
		return _delivery_area.value
	func clear_delivery_area() -> void:
		_delivery_area.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
	func new_delivery_area() -> Environment_Description.Area_Description:
		_delivery_area.value = Environment_Description.Area_Description.new()
		return _delivery_area.value
	
	class Machine:
		func _init():
			var service
			
			_input_area = PBField.new("input_area", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE])
			service = PBServiceField.new()
			service.field = _input_area
			service.func_ref = funcref(self, "new_input_area")
			data[_input_area.tag] = service
			
			_output_area = PBField.new("output_area", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE])
			service = PBServiceField.new()
			service.field = _output_area
			service.func_ref = funcref(self, "new_output_area")
			data[_output_area.tag] = service
			
			_input_size = PBField.new("input_size", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.INT32])
			service = PBServiceField.new()
			service.field = _input_size
			data[_input_size.tag] = service
			
			_output_size = PBField.new("output_size", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, false, DEFAULT_VALUES_2[PB_DATA_TYPE.INT32])
			service = PBServiceField.new()
			service.field = _output_size
			data[_output_size.tag] = service
			
			_processes_list = PBField.new("processes_list", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 5, false, [])
			service = PBServiceField.new()
			service.field = _processes_list
			data[_processes_list.tag] = service
			
		var data = {}
		
		var _input_area: PBField
		func get_input_area() -> Environment_Description.Area_Description:
			return _input_area.value
		func clear_input_area() -> void:
			_input_area.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
		func new_input_area() -> Environment_Description.Area_Description:
			_input_area.value = Environment_Description.Area_Description.new()
			return _input_area.value
		
		var _output_area: PBField
		func get_output_area() -> Environment_Description.Area_Description:
			return _output_area.value
		func clear_output_area() -> void:
			_output_area.value = DEFAULT_VALUES_2[PB_DATA_TYPE.MESSAGE]
		func new_output_area() -> Environment_Description.Area_Description:
			_output_area.value = Environment_Description.Area_Description.new()
			return _output_area.value
		
		var _input_size: PBField
		func get_input_size() -> int:
			return _input_size.value
		func clear_input_size() -> void:
			_input_size.value = DEFAULT_VALUES_2[PB_DATA_TYPE.INT32]
		func set_input_size(value : int) -> void:
			_input_size.value = value
		
		var _output_size: PBField
		func get_output_size() -> int:
			return _output_size.value
		func clear_output_size() -> void:
			_output_size.value = DEFAULT_VALUES_2[PB_DATA_TYPE.INT32]
		func set_output_size(value : int) -> void:
			_output_size.value = value
		
		var _processes_list: PBField
		func get_processes_list() -> Array:
			return _processes_list.value
		func clear_processes_list() -> void:
			_processes_list.value = DEFAULT_VALUES_2[PB_DATA_TYPE.INT32]
		func add_processes_list(value : int) -> void:
			_processes_list.value.append(value)
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Area_Description:
		func _init():
			var service
			
			_x = PBField.new("x", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 1, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _x
			data[_x.tag] = service
			
			_y = PBField.new("y", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 2, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _y
			data[_y.tag] = service
			
			_width = PBField.new("width", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 3, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _width
			data[_width.tag] = service
			
			_height = PBField.new("height", PB_DATA_TYPE.FLOAT, PB_RULE.OPTIONAL, 4, false, DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT])
			service = PBServiceField.new()
			service.field = _height
			data[_height.tag] = service
			
		var data = {}
		
		var _x: PBField
		func get_x() -> float:
			return _x.value
		func clear_x() -> void:
			_x.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_x(value : float) -> void:
			_x.value = value
		
		var _y: PBField
		func get_y() -> float:
			return _y.value
		func clear_y() -> void:
			_y.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_y(value : float) -> void:
			_y.value = value
		
		var _width: PBField
		func get_width() -> float:
			return _width.value
		func clear_width() -> void:
			_width.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_width(value : float) -> void:
			_width.value = value
		
		var _height: PBField
		func get_height() -> float:
			return _height.value
		func clear_height() -> void:
			_height.value = DEFAULT_VALUES_2[PB_DATA_TYPE.FLOAT]
		func set_height(value : float) -> void:
			_height.value = value
		
		func to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PoolByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PoolByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PoolByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
