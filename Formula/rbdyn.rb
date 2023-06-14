class Rbdyn < Formula
  desc "Classes and functions to model the dynamics of rigid body systems"
  homepage "https://github.com/jrl-umi3218/RBDyn"
  url "https://github.com/jrl-umi3218/RBDyn/releases/download/v1.8.2/RBDyn-v1.8.2.tar.gz"
  sha256 "ceac9702fdf4b627b2acf92078766c56b6160b500e282dc9e4c8167216191d05"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/rbdyn-1.8.2"
    sha256 cellar: :any,                 monterey:     "ee41df03ae2481c7bdc2168d1b642532271136c8e8378c5ecc4c7ab40dd51cc8"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "4c53b13502f7849dbaa597fe782c713aa56ee771cf7cf1bc869627b09893842a"
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
