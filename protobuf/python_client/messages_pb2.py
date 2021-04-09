# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: messages.proto
"""Generated protocol buffer code."""
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='messages.proto',
  package='communication_commandes',
  syntax='proto2',
  serialized_options=None,
  create_key=_descriptor._internal_create_key,
  serialized_pb=b'\n\x0emessages.proto\x12\x17\x63ommunication_commandes\"\x9b\x01\n\x07\x43ommand\x12?\n\x07\x63ommand\x18\x01 \x01(\x0e\x32..communication_commandes.Command.Command_types\x12\x0b\n\x03\x64ir\x18\x02 \x01(\x02\x12\r\n\x05speed\x18\x03 \x01(\x02\x12\x0c\n\x04time\x18\x04 \x01(\x02\"%\n\rCommand_types\x12\x08\n\x04GOTO\x10\x00\x12\n\n\x06PICKUP\x10\x01\"\xe7\x02\n\x05State\x12\x11\n\tnb_robots\x18\x01 \x01(\x05\x12\x10\n\x08robots_x\x18\x02 \x03(\x05\x12\x10\n\x08robots_y\x18\x03 \x03(\x05\x12\x11\n\tis_moving\x18\x04 \x03(\x08\x12\x13\n\x0bnb_packages\x18\x05 \x01(\x05\x12\x43\n\x12packages_locations\x18\x06 \x03(\x0b\x32\'.communication_commandes.State.Location\x12\x11\n\tnb_stands\x18\x07 \x01(\x05\x12\x10\n\x08stands_x\x18\x08 \x03(\x05\x12\x10\n\x08stands_y\x18\t \x03(\x05\x1a\x82\x01\n\x08Location\x12\x43\n\rlocation_type\x18\x01 \x01(\x0e\x32,.communication_commandes.State.Location.Type\x12\x13\n\x0blocation_id\x18\x02 \x01(\x05\"\x1c\n\x04Type\x12\t\n\x05ROBOT\x10\x00\x12\t\n\x05STAND\x10\x01'
)



_COMMAND_COMMAND_TYPES = _descriptor.EnumDescriptor(
  name='Command_types',
  full_name='communication_commandes.Command.Command_types',
  filename=None,
  file=DESCRIPTOR,
  create_key=_descriptor._internal_create_key,
  values=[
    _descriptor.EnumValueDescriptor(
      name='GOTO', index=0, number=0,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='PICKUP', index=1, number=1,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
  ],
  containing_type=None,
  serialized_options=None,
  serialized_start=162,
  serialized_end=199,
)
_sym_db.RegisterEnumDescriptor(_COMMAND_COMMAND_TYPES)

_STATE_LOCATION_TYPE = _descriptor.EnumDescriptor(
  name='Type',
  full_name='communication_commandes.State.Location.Type',
  filename=None,
  file=DESCRIPTOR,
  create_key=_descriptor._internal_create_key,
  values=[
    _descriptor.EnumValueDescriptor(
      name='ROBOT', index=0, number=0,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
    _descriptor.EnumValueDescriptor(
      name='STAND', index=1, number=1,
      serialized_options=None,
      type=None,
      create_key=_descriptor._internal_create_key),
  ],
  containing_type=None,
  serialized_options=None,
  serialized_start=533,
  serialized_end=561,
)
_sym_db.RegisterEnumDescriptor(_STATE_LOCATION_TYPE)


_COMMAND = _descriptor.Descriptor(
  name='Command',
  full_name='communication_commandes.Command',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='command', full_name='communication_commandes.Command.command', index=0,
      number=1, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='dir', full_name='communication_commandes.Command.dir', index=1,
      number=2, type=2, cpp_type=6, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='speed', full_name='communication_commandes.Command.speed', index=2,
      number=3, type=2, cpp_type=6, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='time', full_name='communication_commandes.Command.time', index=3,
      number=4, type=2, cpp_type=6, label=1,
      has_default_value=False, default_value=float(0),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
    _COMMAND_COMMAND_TYPES,
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto2',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=44,
  serialized_end=199,
)


_STATE_LOCATION = _descriptor.Descriptor(
  name='Location',
  full_name='communication_commandes.State.Location',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='location_type', full_name='communication_commandes.State.Location.location_type', index=0,
      number=1, type=14, cpp_type=8, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='location_id', full_name='communication_commandes.State.Location.location_id', index=1,
      number=2, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
    _STATE_LOCATION_TYPE,
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto2',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=431,
  serialized_end=561,
)

_STATE = _descriptor.Descriptor(
  name='State',
  full_name='communication_commandes.State',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  create_key=_descriptor._internal_create_key,
  fields=[
    _descriptor.FieldDescriptor(
      name='nb_robots', full_name='communication_commandes.State.nb_robots', index=0,
      number=1, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='robots_x', full_name='communication_commandes.State.robots_x', index=1,
      number=2, type=5, cpp_type=1, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='robots_y', full_name='communication_commandes.State.robots_y', index=2,
      number=3, type=5, cpp_type=1, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='is_moving', full_name='communication_commandes.State.is_moving', index=3,
      number=4, type=8, cpp_type=7, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='nb_packages', full_name='communication_commandes.State.nb_packages', index=4,
      number=5, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='packages_locations', full_name='communication_commandes.State.packages_locations', index=5,
      number=6, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='nb_stands', full_name='communication_commandes.State.nb_stands', index=6,
      number=7, type=5, cpp_type=1, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='stands_x', full_name='communication_commandes.State.stands_x', index=7,
      number=8, type=5, cpp_type=1, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
    _descriptor.FieldDescriptor(
      name='stands_y', full_name='communication_commandes.State.stands_y', index=8,
      number=9, type=5, cpp_type=1, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR,  create_key=_descriptor._internal_create_key),
  ],
  extensions=[
  ],
  nested_types=[_STATE_LOCATION, ],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto2',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=202,
  serialized_end=561,
)

_COMMAND.fields_by_name['command'].enum_type = _COMMAND_COMMAND_TYPES
_COMMAND_COMMAND_TYPES.containing_type = _COMMAND
_STATE_LOCATION.fields_by_name['location_type'].enum_type = _STATE_LOCATION_TYPE
_STATE_LOCATION.containing_type = _STATE
_STATE_LOCATION_TYPE.containing_type = _STATE_LOCATION
_STATE.fields_by_name['packages_locations'].message_type = _STATE_LOCATION
DESCRIPTOR.message_types_by_name['Command'] = _COMMAND
DESCRIPTOR.message_types_by_name['State'] = _STATE
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

Command = _reflection.GeneratedProtocolMessageType('Command', (_message.Message,), {
  'DESCRIPTOR' : _COMMAND,
  '__module__' : 'messages_pb2'
  # @@protoc_insertion_point(class_scope:communication_commandes.Command)
  })
_sym_db.RegisterMessage(Command)

State = _reflection.GeneratedProtocolMessageType('State', (_message.Message,), {

  'Location' : _reflection.GeneratedProtocolMessageType('Location', (_message.Message,), {
    'DESCRIPTOR' : _STATE_LOCATION,
    '__module__' : 'messages_pb2'
    # @@protoc_insertion_point(class_scope:communication_commandes.State.Location)
    })
  ,
  'DESCRIPTOR' : _STATE,
  '__module__' : 'messages_pb2'
  # @@protoc_insertion_point(class_scope:communication_commandes.State)
  })
_sym_db.RegisterMessage(State)
_sym_db.RegisterMessage(State.Location)


# @@protoc_insertion_point(module_scope)
