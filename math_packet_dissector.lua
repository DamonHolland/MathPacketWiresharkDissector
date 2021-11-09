MATH_PORT = 8080
ENDL = "\n"
SPACE = " "
COLON = ":"

------------------------- Build Request Protocol ----------------------------
req_proto = Proto ("MATHRQ",  "Math Request Protocol")
req_comm = ProtoField.string ("req_proto.comm", "Command", base.ASCII)
req_ver = ProtoField.string ("req_proto.ver", "Version", base.ASCII)
req_op1 = ProtoField.string ("req_proto.op1", "Operand 1", base.ASCII)
req_optor = ProtoField.string ("req_proto.optor", "Operator", base.ASCII)
req_op2 = ProtoField.string ("req_proto.op2", "Operand 2", base.ASCII)
req_conn = ProtoField.string ("req_proto.conn", "Connection", base.ASCII)
req_proto.fields = {req_comm, req_ver, req_op1, req_optor, req_op2, req_conn}
comm_field_val = Field.new ("req_proto.comm")

-- Define Protocol Dissector
function req_proto.dissector (buffer, pinfo, tree)
  local CALCULATE = "CALCULATE"
  local buff_pos = 0
  local mathTree = tree:add (req_proto, buffer (), "Math Request")
  pinfo.cols.protocol = req_proto.name
  -- Parse Command
  mathTree:add_le (req_comm, buffer (buff_pos, find_end (buff_pos, SPACE)))
  -- Parse Version
  buff_pos = buff_pos + find_end (buff_pos, SPACE) + 1
  mathTree:add_le (req_ver, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Operand 1
  if tostring (comm_field_val ()) == CALCULATE then
    buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
    mathTree:add_le (req_op1, buffer (buff_pos, find_end (buff_pos, ENDL)))
  end
  -- Parse Operator
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (req_optor, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Operand 2
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (req_op2, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Connection
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (req_conn, buffer (buff_pos, find_end (buff_pos, ENDL)))
end
-------------------------- Request Protocol End -----------------------------


------------------------- Build Response Protocol ---------------------------
res_proto = Proto ("MATHRS",  "Math Response Protocol")
res_ver = ProtoField.string ("res_proto.ver", "Version", base.ASCII)
res_code = ProtoField.string ("res_proto.code", "Code", base.ASCII)
res_res = ProtoField.string ("res_proto.res", "Result", base.ASCII)
res_round = ProtoField.string ("res_proto.round", "Rounding", base.ASCII)
res_over = ProtoField.string ("res_proto.over", "Overflow", base.ASCII)
res_conn = ProtoField.string ("res_proto.conn", "Connection", base.ASCII)
res_xstr = ProtoField.string ("res_proto.xstr", "X-String", base.ASCII)
res_proto.fields = {res_ver, res_code, res_res,
                    res_round, res_over, res_conn, res_xstr}
code_field_val = Field.new ("res_proto.code")

-- Define Protocol Dissector
function res_proto.dissector (buffer, pinfo, tree)
  local SUCCESS_CODE = "100 OK"
  local X_STRING = "X"
  local X_NEXT = '-'
  local buff_pos = 0
  local mathTree = tree:add (res_proto, buffer (), "Math Response")
  pinfo.cols.protocol = res_proto.name
  -- Parse Version
  mathTree:add_le (res_ver, buffer (buff_pos, find_end (buff_pos, SPACE)))
  -- Parse Response Code
  buff_pos = buff_pos + find_end (buff_pos, SPACE) + 1
  mathTree:add_le (res_code, buffer (buff_pos, find_end (buff_pos, ENDL)))
  if tostring (code_field_val ()) ~= SUCCESS_CODE then
    buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
    mathTree:add_le (res_conn, buffer (buff_pos, find_end (buff_pos, ENDL)))
    return end
  -- Parse Result
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (res_res, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Rounding
  repeat 
    buff_pos = buff_pos + find_end (buff_pos, ENDL) + 1
  until (buffer (buff_pos,1):le_uint () ~= string.byte (X_STRING))
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (res_round, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Overflow
  repeat 
    buff_pos = buff_pos + find_end (buff_pos, ENDL) + 1
  until (buffer (buff_pos,1):le_uint () ~= string.byte (X_STRING))
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (res_over, buffer (buff_pos, find_end (buff_pos, ENDL)))
  -- Parse Connection
  repeat 
    buff_pos = buff_pos + find_end (buff_pos, ENDL) + 1
  until (buffer (buff_pos,1):le_uint () ~= string.byte (X_STRING))
  buff_pos = buff_pos + find_end (buff_pos, COLON) + 2
  mathTree:add_le (res_conn, buffer (buff_pos, find_end (buff_pos, ENDL)))
  --Parse X-Strings
  buff_pos = 0
  while find_end (buff_pos, X_STRING) do
    buff_pos = buff_pos + find_end (buff_pos, X_STRING)
    if (buffer (buff_pos + 1,1):le_uint () == string.byte (X_NEXT)) then
      mathTree:add_le (res_xstr, buffer (buff_pos, find_end (buff_pos, ENDL)))
    end
    buff_pos = buff_pos + 1
  end
end
-------------------------- Response Protocol End ----------------------------


------------------------- Build Wrapper Protocol ----------------------------
--------------------- Determines which protocol to use ----------------------
math_wapper_proto = Proto ("MATHW",  "Math Wrapper Protocol")
function math_wapper_proto.dissector (buffer, pinfo, tree)
  if buffer:len () == 0 then return end

  -- Helper Function for Finding Character Index in Buffer
  function find_end (start_point, end_char)
    for i = start_point, buffer:len () - 1, 1 do
      if (buffer (i,1):le_uint () == string.byte (end_char)) then
        return i - start_point
      end
    end
  end
  
  -- Determine which dissector to use
  if pinfo.dst_port == MATH_PORT then
    req_proto.dissector (buffer, pinfo, tree)
  elseif pinfo.src_port == MATH_PORT then
    -- Reassemble packets if response terminator has not been recieved
    if (buffer (buffer:len () - 2,1):le_uint () ~= string.byte (ENDL)) or
       (buffer (buffer:len () - 1,1):le_uint () ~= string.byte (ENDL)) then
      pinfo.desegment_len = DESEGMENT_ONE_MORE_SEGMENT
    else
      res_proto.dissector (buffer, pinfo, tree)
    end
  end
end

-- Set Wireshark Port for Wrapper Protocol
DissectorTable.get ("tcp.port"):add (MATH_PORT, math_wapper_proto)
--------------------------- Wrapper Protocol End ----------------------------
