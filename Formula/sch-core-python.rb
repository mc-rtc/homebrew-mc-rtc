class SchCorePython < Formula
  desc "Python bindings for the sch library"
  homepage "https://github.com/jrl-umi3218/sch-core-python/"
  url "https://github.com/jrl-umi3218/sch-core-python/releases/download/v1.0.2/sch-core-python-v1.0.2.tar.gz"
  sha256 "89e4ce4d5a479a62aba5450bf6d22540fded2e3ea7c34e177c9606104ead64f1"
  license "BSD-2-Clause"
  revision 3

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/sch-core-python-1.0.2_3"
    sha256 cellar: :any,                 big_sur:      "d854d052cfc27a438ff9987c32ca08b8a228176f66e50639f0b9913822e8d953"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "8059f9982574a97591aa2525574534e3cf6416d9f146b78931667be544ed9f40"
  end

  depends_on "cmake" => :build
  depends_on "cython" => :build
  depends_on "sch-core"
  depends_on "spacevecalg"

  def install
    xy = Language::Python.major_minor_version Formula["python"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    inreplace "CMakeLists.txt",
              "set(PIP_EXTRA_OPTIONS --target \"${PIP_TARGET}\")",
              "set(PIP_EXTRA_OPTIONS --prefix \"${PIP_INSTALL_PREFIX}\")"

    args = std_cmake_args + %W[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPIP_INSTALL_PREFIX=#{prefix}
      -DPYTHON_BINDING_FORCE_PYTHON3:BOOL=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import sch
    EOS
  end
end
