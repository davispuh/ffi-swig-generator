require File.join(File.dirname(__FILE__), %w[.. spec_helper])

include FFI

share_examples_for "All specs" do
  after :all do
    remove_xml
  end
end

describe Generator::Parser do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('testlib')
  end
  it 'should generate ruby ffi wrap code' do
    Generator::Parser.generate(@node).should == <<EOC

module TestLib
  extend FFI::Library
  CONST_1 = 0x10
  CONST_2 = 0x20
  ENUM_1 = 0
  ENUM_2 = 1
  ENUM_3 = 2

  class UnionT < FFI::Union
    layout(
           :c, :char,
           :f, :float
    )
  end
  class TestStruct < FFI::Struct
    layout(
           :i, :int,
           :c, :char,
           :b, :uchar
    )
  end
  class CamelCaseStruct < FFI::Struct
    layout(
           :i, :int,
           :c, :char,
           :b, :uchar
    )
  end
  class TestStruct3 < FFI::Struct
    layout(
           :c, :char
    )
  end
  callback(:cb, [ :string, :string ], :void)
  callback(:cb_2, [ :string, :string ], :pointer)
  callback(:cb_3, [ :string, CamelCaseStruct ], CamelCaseStruct)
  class TestStruct2 < FFI::Struct
    layout(
           :s, TestStruct,
           :camel_case_struct, CamelCaseStruct,
           :s_3, TestStruct3,
           :e, :int,
           :func, :cb,
           :u, UnionT,
           :callback, :cb,
           :inline_callback, callback([  ], :void)
    )
    def func=(cb)
      @func = cb
      self[:func] = @func
    end
    def func
      @func
    end
    def callback=(cb)
      @callback = cb
      self[:callback] = @callback
    end
    def callback
      @callback
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  class TestStruct4 < FFI::Struct
    layout(
           :string, :pointer,
           :inline_callback, callback([  ], :void)
    )
    def string=(str)
      @string = FFI::MemoryPointer.from_string(str)
      self[:string] = @string
    end
    def string
      @string.get_string(0)
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  class TestStruct5BigUnionFieldNestedStructField1 < FFI::Struct
    layout(
           :a, :int,
           :b, :int
    )
  end
  class TestStruct5BigUnionFieldNestedStructField2 < FFI::Struct
    layout(
           :c, :int,
           :d, :int
    )
  end
  class TestStruct5BigUnionFieldNestedStructField3 < FFI::Struct
    layout(
           :e, :int,
           :f, :int
    )
  end
  class TestStruct5BigUnionFieldUnionField < FFI::Union
    layout(
           :l, :long,
           :ll, :long_long
    )
  end
  class TestStruct5BigUnionField < FFI::Union
    layout(
           :union_field, TestStruct5BigUnionFieldUnionField,
           :nested_struct_field_3, TestStruct5BigUnionFieldNestedStructField3,
           :nested_struct_field_2, TestStruct5BigUnionFieldNestedStructField2,
           :nested_struct_field_1, TestStruct5BigUnionFieldNestedStructField1
    )
  end
# FIXME: Nested structures are not correctly supported at the moment.
# Please check the order of the declarations in the structure below.
#   class TestStruct5 < FFI::Struct
#     layout(
#            :i, :int,
#            :c, :char,
#            :big_union_field, TestStruct5BigUnionField
#     )
#   end
  attach_function :get_int, [ :pointer ], :int
  attach_function :get_char, [ :pointer ], :char
  attach_function :func_with_enum, [ :int ], :int
  attach_function :func_with_enum_2, [ :int ], :int
  attach_function :func_with_typedef, [  ], :uchar

end
EOC
  end
end

describe Generator::Constant do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('constants')
  end
  it 'should return a ruby constant assignment' do
    Generator::Constant.new(:node => @node / 'constant').to_s.should == "CONST_1 = 0x10"
  end
end

describe Generator::Enum do
  before :all do
    @node = generate_xml_wrap_from('enums')
  end
  it 'should generate constants' do
    Generator::Enum.new(:node => (@node / 'enum')[0]).to_s.should == <<EOE
ENUM_1 = 0
ENUM_2 = 1
ENUM_3 = 2
EOE
  end
  it 'should generate constants starting from the latest assignment' do
    Generator::Enum.new(:node => (@node / 'enum')[1]).to_s.should == <<EOE
ENUM_21 = 2
ENUM_22 = 3
ENUM_23 = 4
EOE
    Generator::Enum.new(:node => (@node / 'enum')[2]).to_s.should == <<EOE
ENUM_31 = 0
ENUM_32 = 5
ENUM_33 = 6
EOE
  end
end

describe Generator::Type do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('types')
  end
  it 'should generate string type' do
    Generator::Type.new(:node => (@node / 'cdecl')[0]).to_s.should == ':string'
  end
  it 'should generate pointer type' do
    Generator::Type.new(:node => (@node / 'cdecl')[1]).to_s.should == ':pointer'
    Generator::Type.new(:node => (@node / 'cdecl')[2]).to_s.should == ':pointer'
  end
  it 'should generate array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[3]).to_s.should == '[:int, 5]'
    Generator::Type.new(:node => (@node / 'cdecl')[4]).to_s.should == '[:string, 5]'
  end
  it 'should generate struct type' do
    Generator::Type.new(:node => (@node / 'cdecl')[6]).to_s.should == 'TestStruct'
  end
  it 'should generate struct array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[7]).to_s.should == '[TestStruct, 5]'
  end
  it 'should generate enum array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[8]).to_s.should == '[:int, 5]'
  end
  it 'should generate const type' do
    Generator::Type.new(:node => (@node / 'cdecl')[9]).to_s.should == ':int'
    Generator::Type.new(:node => (@node / 'cdecl')[10]).to_s.should == ':string'
  end
  Generator::TYPES.sort.each_with_index do |type, i|
    it "should generate #{type[0]} type" do
      Generator::Type.new(:node => (@node / 'cdecl')[i + 11]).to_s.should == type[1]
    end 
  end
end

describe Generator::Function do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('functions')
  end
  it 'should return a properly generated attach_method' do
    Generator::Function.new(:node => (@node / 'cdecl')[0]).to_s.should == "attach_function :func_1, [ :char, :int ], :int"
  end
  it 'should properly generate pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[1]).to_s.should == "attach_function :func_2, [ :pointer, :pointer, :pointer ], :uint"
  end
  it 'should properly generate string arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[2]).to_s.should == "attach_function :func_3, [ :string ], :void"
  end
  it 'should properly generate string return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[3]).to_s.should == "attach_function :func_4, [ :int ], :string"
  end
  it 'should generate string type only in case of pointer of type char (char *)' do
    Generator::Function.new(:node => (@node / 'cdecl')[17]).to_s.should == "attach_function :func_17, [  ], :pointer"
  end
  it 'should properly generate void return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[4]).to_s.should == "attach_function :func_5, [  ], :void"
  end
  it 'should properly generate pointer of pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[5]).to_s.should == "attach_function :func_6, [ :pointer ], :void"
  end
  it 'should properly generate enum arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[6]).to_s.should == "attach_function :func_7, [ :int ], :void"
  end
  it 'should properly generate enum return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[7]).to_s.should == "attach_function :func_8, [  ], :int"
  end
  it 'should properly generate struct arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[9]).to_s.should == "attach_function :func_9, [ TestStruct ], :void"
  end
  it 'should properly generate struct return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[10]).to_s.should == "attach_function :func_10, [  ], TestStruct"
  end
  it 'should properly generate a function with no parameters' do
    Generator::Function.new(:node => (@node / 'cdecl')[11]).to_s.should == "attach_function :func_11, [  ], :void"
  end
  it 'should properly generate a function that takes a callback as argument' do
    Generator::Function.new(:node => (@node / 'cdecl')[12]).to_s.should == "attach_function :func_12, [ callback([ :float ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[13]).to_s.should == "attach_function :func_13, [ callback([ :double, :float ], :int) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[14]).to_s.should == "attach_function :func_14, [ callback([ :string ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[15]).to_s.should == "attach_function :func_15, [ callback([  ], :void) ], :void"
  end
  it 'should handle const qualifier return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[16]).to_s.should == "attach_function :func_16, [  ], :string"
  end
  it 'should generate a function with variadic args' do
    Generator::Function.new(:node => (@node / 'cdecl')[18]).to_s.should == "attach_function :func_18, [ :varargs ], :void"
  end
  it 'should generate a function with volatile args' do
    Generator::Function.new(:node => (@node / 'cdecl')[19]).to_s.should == "attach_function :func_19, [ :int ], :void"
  end
end

describe Generator::Structure do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('structs')
  end
  it 'should properly generate the layout of a FFI::Struct class' do
    Generator::Structure.new(:node => (@node / 'class')[0]).to_s.should == <<EOC
class TestStruct1 < FFI::Struct
  layout(
         :i, :int,
         :c, :char,
         :s, :pointer,
         :a, [:char, 5]
  )
  def s=(str)
    @s = FFI::MemoryPointer.from_string(str)
    self[:s] = @s
  end
  def s
    @s.get_string(0)
  end

end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing pointer field' do
    Generator::Structure.new(:node => (@node / 'class')[1]).to_s.should == <<EOC
class TestStruct2 < FFI::Struct
  layout(
         :ptr, :pointer
  )
end
EOC
end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Structure.new(:node => (@node / 'class')[2]).to_s.should == <<EOC
class TestStruct3 < FFI::Struct
  layout(
         :c, [:char, 5]
  )
end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Structure.new(:node => (@node / 'class')[3]).to_s.should == <<EOC
class TestStruct4 < FFI::Struct
  layout(
         :s, [TestStruct3, 5]
  )
end
EOC

  end
end

describe Generator::Union do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('unions')
  end
  it 'should properly generate the layout of a FFI::Union class' do
    Generator::Union.new(:node => (@node / 'class')[0]).to_s.should == <<EOC
class UnionT < FFI::Union
  layout(
         :c, :char,
         :f, :float
  )
end
EOC
  end
end

