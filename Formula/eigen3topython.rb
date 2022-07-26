class Eigen3topython < Formula
  desc "Provide Eigen3 to numpy conversion"
  homepage "https://github.com/jrl-umi3218/Eigen3ToPython"
  url "https://github.com/jrl-umi3218/Eigen3ToPython/releases/download/v1.0.2/Eigen3ToPython-v1.0.2.tar.gz"
  sha256 "36b4462e7a924eee0dc8462ce56e5cc58e7196d9b6b4732750462fb507934de0"
  license "BSD-2-Clause"
  revision 1

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/eigen3topython-1.0.2_1"
    sha256 cellar: :any_skip_relocation, big_sur:      "09b6cdd142ec0378df584b90603d6479ba115aa7b40a06912dd07ceb025e1e2e"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "81c60ef076a1acd4d1153355a7080300103942e464b429816733c027d21e7a6e"
  end

  depends_on "cmake" => :build
  depends_on "cython" => :build
  depends_on "eigen" => :build
  depends_on "numpy"
  depends_on "python"

  # The patch removes the requirement on coverage and nose which are not needed here
  patch :DATA

  def install
    xy = Language::Python.major_minor_version Formula["python@3.9"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    args = std_cmake_args + %W[
      -DPIP_INSTALL_PREFIX=#{prefix}
      -DPYTHON_BINDING_FORCE_PYTHON3:BOOL=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import eigen
      print("Eigen version: {}".format(eigen.EigenVersion()))
      print("Random Vector3d: {}".format(eigen.Vector3d.Random().transpose()))
    EOS
  end
end
__END__
diff --git a/requirements.txt b/requirements.txt
index 1815ab1..a4ce253 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,4 +1,2 @@
 Cython>=0.2
-coverage
-nose
 numpy>=1.8.2
