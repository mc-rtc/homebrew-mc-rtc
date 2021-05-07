class Rbdyn < Formula
  desc "Classes and functions to model the dynamics of rigid body systems"
  homepage "https://github.com/jrl-umi3218/RBDyn"
  url "https://github.com/jrl-umi3218/RBDyn/releases/download/v1.4.0/RBDyn-v1.4.0.tar.gz"
  sha256 "fda8416586a96e0ecb8a66a73c5ade22ba072d5b32722538b8b87f3e80134bd7"
  license "BSD-2-Clause"

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

    inreplace "cmake/cython/cython.cmake" do |s|
      s.gsub! "set(PIP_EXTRA_OPTIONS --target \"${PIP_TARGET}\")",
              "set(PIP_EXTRA_OPTIONS --prefix \"${PIP_INSTALL_PREFIX}\")"
      s.gsub! "COMMAND ${CMAKE_COMMAND} -E chdir \"${SETUP_LOCATION}\" ${PYTHON} setup.py build_ext --inplace",
              "COMMAND ${CMAKE_COMMAND} -E env \"HOMEBREW_ARCHFLAGS=-march=core2\"
                       ${CMAKE_COMMAND} -E chdir \"${SETUP_LOCATION}\" ${PYTHON} setup.py build_ext --inplace"
    end

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
    system "cmake", ".", *std_cmake_args
    system "make"
    system "ldd ./main || otool -L ./main"
    system "./main"

    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import rbdyn
    EOS
  end
end
