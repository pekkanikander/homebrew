# -*- coding: undecided -*-
require 'formula'
require 'find'


class YagartoBinutils < Formula
  homepage 'http://yagarto.de/'
  url 'http://www.yagarto.de/source/toolchain/binutils-2.22.tar.bz2'
  sha1 '65b304a0b9a53a686ce50a01173d1f40f8efe404'

  def patches
    Dir["#{ENV['YAGARTO_BUILDPATH']}/patches/binutils-*.patch"]
  end

  def install target, prefix
    system "./configure", "--target=#{target}", "--prefix=#{prefix}", "--disable-shared",
      "--disable-nls", "--disable-threads", "--enable-interwork", "--enable-multilib",
      "--with-gcc", "--with-gnu-as", "--with-gnu-ld"
    system "make"
    system "make", "install"
  end

end

class YagartoNewlib < Formula
  homepage 'http://yagarto.de/'
  url 'http://www.yagarto.de/source/toolchain/newlib-1.20.0.tar.gz'
  sha1 '65e7bdbeda0cbbf99c8160df573fd04d1cbe00d1'

  def patches
    Dir["#{ENV['YAGARTO_BUILDPATH']}/patches/newlib-*.patch"]
  end

  def install target, prefix
    system "./configure", "--target=#{target}", "--prefix=#{prefix}",
       "--disable-newlib-supplied-syscalls", "--enable-interwork", "--enable-multilib"
    system "make"
    system "make", "install"
  end
end

class YagartoGcc < Formula
  homepage 'http://yagarto.de/'
  url 'http://www.yagarto.de/source/toolchain/gcc-4.7.1.tar.bz2'
  sha1 '3ab74e63a8f2120b4f2c5557f5ffec6907337137'

  def patches
    "#{ENV['YAGARTO_BUILDPATH']}/patches/gcc-4.7.1.patch"
  end

  def boot target, prefix, newlib
    system "mkdir -p build"
    Dir.chdir "build" do
      system "../configure", "--target=#{target}", "--prefix=#{prefix}", "--disable-shared",
        "--disable-decimal-float", "--disable-libmudflap", "--disable-libquadmath",
        "--disable-nls", "--disable-threads", "-disable-libssp", "--disable-libstdcxx-pch",
        "--disable-libmudflap", "--disable-libgomp", "-v",
        "--enable-languages=c,c++", "--enable-interwork", "--enable-multilib",
        "--with-gcc", "--with-gnu-ld", "--with-gnu-as", "--with-dwarf2",
        "--with-newlib", "--with-headers=#{newlib}/newlib/libc/include",
        "--with-mpc=#{HOMEBREW_PREFIX}", "--with-mpfr=#{HOMEBREW_PREFIX}", "--with-gmp=#{HOMEBREW_PREFIX}"

      system "mkdir", "-p", "libiberty", "libcpp", "fixincludes"

      system "make", "all-gcc"
      system "make", "install-gcc"
    end
  end

  def install
    Dir.chdir "build" do
      system "make"
      system "make", "install"
    end
  end
end

class YagartoGdb < Formula
  url 'http://www.yagarto.de/source/toolchain/gdb-7.4.1.tar.bz2'
  homepage 'http://yagarto.de/'
  sha1 '1b0f8c3778d4b10c8d2be6922ac01a9900e8116c'

  def install target, prefix
    system "./configure", "--target=#{target}", "--prefix=#{prefix}", "--disable-shared",
      "--disable-nls", "--disable-threads", "--with-libexpat-prefix=#{prefix}"
    system "make"
    system "make", "install"
  end
end

class ArmEabiGccYagarto < Formula
  homepage 'http://www.yagarto.de'
  url 'http://www.yagarto.de/source/toolchain/build-scripts-20120616.tar.bz2'
  version '20120616'
  sha1 '318af3b04b6b3087ddac12ac83a8c036551b2575'

  depends_on 'expat'
  depends_on 'gmp'
  depends_on 'mpfr'
  depends_on 'libmpc'
  depends_on 'wget'

  # Define the target triple
  TARGET = "arm-none-eabi"

  def install
    # Undefine LD, gcc expects that this will not be set
    ENV.delete 'LD'

    # Compiling a cross compiler precludes the use of the normal bootstrap
    # compiler process so we need to use GCC to compile the toolchain. Luckily
    # LLVM-GCC works.
    ENV.llvm

    # Halfway through the build process the compiler switches to an internal
    # version of gcc that does not understand Apple specific options.
    ENV.cc_flag_vars.each do |var|
      ENV.delete var
    end
    ENV.delete 'CPPFLAGS'
    ENV.delete 'LDFLAGS'
    unless HOMEBREW_PREFIX.to_s == '/usr/local'
      ENV['CPPFLAGS'] = "-I#{HOMEBREW_PREFIX}/include"
      ENV['LDFLAGS'] = "-L#{HOMEBREW_PREFIX}/lib"
    end

    # We need to use our toolchain during the build process, prepend it to PATH
    ENV.prepend 'PATH', bin, ':'
    ENV['YAGARTO_BUILDPATH'] = buildpath

    binutils = YagartoBinutils.new
    newlib = YagartoNewlib.new
    gcc = YagartoGcc.new
    gdb = YagartoGdb.new

    binutils.brew { binutils.install TARGET, prefix }

    gcc.brew {
      newlib.brew {
        Dir.chdir gcc.buildpath do
          gcc.boot TARGET, prefix, newlib.buildpath
        end
        ENV.deparallelize
        newlib.install TARGET, prefix
        ENV['MAKEFLAGS'] = "-j#{ENV.make_jobs}"
        Dir.chdir gcc.buildpath do
          gcc.install
        end
      }
    }

    gdb.brew      { gdb.install TARGET, prefix }

    Find.find("#{prefix}") do |path|
      basename = File.basename(path)
      if basename == "crt0.0" or File.fnmatch("*.la", basename)
        File.unlink(path)
      end
    end
  end

  def test
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test build-scripts`.
    system "false"
  end
end
__END__
