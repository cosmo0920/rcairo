require 'cairo'
require 'ffi'

class QuartzSurfaceTest < Test::Unit::TestCase
  include CairoTestUtils

  def setup
    only_surface("Quartz")
  end

  def test_new
    surface = Cairo::QuartzSurface.new(100, 100)
    assert_kind_of(Cairo::QuartzSurface, surface)
  end

  def test_ruby_cocoa
    assert_nothing_raised do
      surface = Cairo::QuartzSurface.new(100, 100)
      surface.cg_context
    end
  end

  def test_cFFIPointer
    assert_nothing_raised do
      FFI::Function.new(:void, [:pointer]) do |cr|
        context = Cairo::Context.wrap(FFI::Pointer.new(cr))
        Cairo::QuartzSurface.new(context.to_ptr, 100, 100)
      end
    end
  end
end
