class Rbdyn < Formula
  desc "Classes and functions to model the dynamics of rigid body systems"
  homepage "https://github.com/jrl-umi3218/RBDyn"
  url "https://github.com/jrl-umi3218/RBDyn/releases/download/v1.7.2/RBDyn-v1.7.2.tar.gz"
  sha256 "8c2881cda829516e988cf598cbd89183ea8decedaa6f1ab4ec28a1f7a96de096"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/rbdyn-1.6.0_1"
    sha256 cellar: :any,                 big_sur:      "106ded6d8264f23fbba6a4a4657ad5804dc996e78ceeaf13593c6417c2826314"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "28175910b2f67ac9277b1df23c7fbf2d26c0847758c6e6ed2182194c01ae8404"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"
  depends_on "spacevecalg"
  depends_on "tinyxml2"
  depends_on "yaml-cpp"

  resource "urdf" do
    url "https://raw.githubusercontent.com/jrl-umi3218/RBDyn/v1.4.0/tests/ParsersTestUtils.h"
    sha256 "48d44698adcb6eb84d8a0c7e88488d501d62f2e4157754a20afe1e683675e03e"
  end

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPYTHON_BINDING:BOOL=OFF
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
  end
end
