require 'formula'

# Documentation: https://github.com/mxcl/homebrew/wiki/Formula-Cookbook
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!

class Stlink < Formula
  homepage 'https://github.com/texane/stlink'
  head 'https://github.com/texane/stlink.git'

  depends_on 'autoconf'
  depends_on 'automake'
  depends_on 'libusb'
  depends_on 'pkg-config'

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end

  def test
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test stlink`.
    system "false"
  end
end
