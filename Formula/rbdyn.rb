class Rbdyn < Formula
  desc "Classes and functions to model the dynamics of rigid body systems"
  homepage "https://github.com/jrl-umi3218/RBDyn"
  url "https://github.com/jrl-umi3218/RBDyn/releases/download/v1.5.0/RBDyn-v1.5.0.tar.gz"
  sha256 "d018f57a354a4ea8e0cd50c2fdf018f9a510ff8cc34a12d12cff793120458e5b"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/rbdyn-1.5.0"
    sha256 cellar: :any,                 catalina:     "3653942da738e3ad1c1446c2d092d9188a9e1d7ee35e359757e6eefd4a032fcb"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "09e78c56b5b93711a06420f64e774cd70eb1f36f83757d8f0293ca80caec68d2"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "boost"
  depends_on "spacevecalg"
  depends_on "tinyxml2"
  depends_on "yaml-cpp"

  resource "urdf" do
    url "https://raw.githubusercontent.com/jrl-umi3218/RBDyn/v1.4.0/tests/ParsersTestUtils.h"
    sha256 "48d44698adcb6eb84d8a0c7e88488d501d62f2e4157754a20afe1e683675e03e"
  end

  def install
    xy = Language::Python.major_minor_version Formula["python"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

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
    resource("urdf").stage testpath

    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewRBDyn LANGUAGES CXX)
      find_package(RBDyn REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC RBDyn::RBDyn RBDyn::Parsers)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <RBDyn/CoM.h>
      #include <RBDyn/parsers/urdf.h>
      #include <iostream>

      #include "ParsersTestUtils.h"

      int main() {
        std::cout << "Loading robot\\n";
        auto robot = rbd::parsers::from_urdf(XYZSarmUrdf);
        std::cout << "Robot has: " << robot.mb.nrDof() << " dof\\n";
        double mass = 0.0;
        for(const auto & b : robot.mb.bodies())
        {
          mass += b.inertia().mass();
        }
        std::cout << "Robot mass: " << mass << "\\n";
        std::cout << "Compute CoM\\n";
        auto com = rbd::computeCoM(robot.mb, robot.mbc);
        std::cout << "CoM: " << com.transpose() << "\\n";
        return 0;
      }
    EOS
    # Avoid introducing march=native which will cause ABI breaks
    ENV["CXXFLAGS"] = ""
    system "cmake", ".", *std_cmake_args
    system "cmake", "--build", "."
    system "./main"

    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import rbdyn
    EOS
  end
end
