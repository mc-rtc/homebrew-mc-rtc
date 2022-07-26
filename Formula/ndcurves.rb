class Ndcurves < Formula
  desc "Library for creating smooth cubic splines"
  homepage "https://github.com/loco-3d/ndcurves"
  url "https://github.com/loco-3d/ndcurves/releases/download/v1.1.4/ndcurves-1.1.4.tar.gz"
  sha256 "5318f5ebb40cb443e42561e88a09c505f89eefffa0ad1b122bdac34d0468f7e4"
  license "BSD-2-Clause"
  revision 1

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/ndcurves-1.1.4"
    sha256 cellar: :any_skip_relocation, big_sur:      "7302a11bfe6d7050464887799af29222b44a5ea030716d8131c57a583bc94f9a"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "3c3ad5ac682cd58bc40768f03e683bbf1dcc9e3062abbfc859c869154feb3a1b"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"
  depends_on "eigen"

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DBUILD_TESTING:BOOL=OFF
      -DBUILD_PYTHON_INTERFACE:BOOL=OFF
      -DINSTALL_DOCUMENTATION:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(Brewndcurves LANGUAGES CXX)
      find_package(ndcurves REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC ndcurves::ndcurves)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <iostream>

      #include <ndcurves/exact_cubic.h>
      #include <ndcurves/bezier_curve.h>
      #include <ndcurves/helpers/effector_spline.h>
      #include <ndcurves/helpers/effector_spline_rotation.h>

      // loading helper class namespace
      using namespace ndcurves::helpers;

      int main()
      {
        // Create waypoints
        T_Waypoint waypoints;
        waypoints.push_back(std::make_pair(0., Eigen::Vector3d(0,0,0)));
        waypoints.push_back(std::make_pair(1., Eigen::Vector3d(0.5,0.5,0.5)));
        waypoints.push_back(std::make_pair(2., Eigen::Vector3d(1,1,0)));

        exact_cubic_t* eff_traj = effector_spline(waypoints.begin(),waypoints.end());

        // evaluate spline
        std::cout << (*eff_traj)(0.).transpose() << std::endl; // (0,0,0)
        std::cout << (*eff_traj)(2.).transpose() << std::endl; // (1,1,0)

        return 0;
      }
    EOS
    # Avoid introducing march=native which will cause ABI breaks
    ENV["CXXFLAGS"] = ""
    system "cmake", ".", *std_cmake_args
    system "make"
    system "./main"
  end
end
