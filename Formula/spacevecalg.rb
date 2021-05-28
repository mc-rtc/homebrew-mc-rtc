class Spacevecalg < Formula
  desc "Implementation of spatial vector algebra with the Eigen3 linear algebra library"
  homepage "https://github.com/jrl-umi3218/SpaceVecAlg"
  url "https://github.com/jrl-umi3218/SpaceVecAlg/releases/download/v1.2.0/SpaceVecAlg-v1.2.0.tar.gz"
  sha256 "de18b1109853df6e8e7ac71ae946b2076321bb43c8d89837e610e800e303a37a"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/spacevecalg-1.1.1"
    sha256 cellar: :any_skip_relocation, catalina:     "20ec29362dbfdc48b7bd8dc1ff0c3a099ecb56f9b3f9c59b22f61e5292f54d00"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "c31a65f4c77bb51469c65fadbb1f1d211d73650190afaf3e079e5f8bd8b1965c"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "eigen"
  depends_on "eigen3topython"

  def install
    xy = Language::Python.major_minor_version Formula["python"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    inreplace "cmake/cython/cython.cmake",
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
      import sva
      print(sva.PTransformd.Identity())
    EOS

    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewSpaceVecAlg LANGUAGES CXX)
      find_package(SpaceVecAlg REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC SpaceVecAlg::SpaceVecAlg)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <SpaceVecAlg/SpaceVecAlg>
      #include <iostream>

      int main() {
        auto pt = sva::PTransformd::Identity();
        std::cout << pt.rotation() << "\\n" << pt.translation().transpose() << "\\n";
        return 0;
      }
    EOS
    system "cmake", ".", *std_cmake_args
    system "make"
    system "./main"
  end
end
