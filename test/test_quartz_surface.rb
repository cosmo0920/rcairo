require 'cairo'

class QuartzSurfaceTest < Test::Unit::TestCase
  include CairoTestUtils

  def setup
    only_surface("Quartz")
  end

  def test_new
    surface = Cairo::QuartzSurface.new(100, 100)
    assert_kind_of(Cairo::QuartzSurface, surface)
  end
end
