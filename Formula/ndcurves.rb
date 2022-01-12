class Ndcurves < Formula
  desc "Library for creating smooth cubic splines"
  homepage "https://github.com/loco-3d/ndcurves"
  url "https://github.com/loco-3d/ndcurves/releases/download/v1.1.1/ndcurves-1.1.1.tar.gz"
  sha256 "115eb4f8dffab324457dc1d56db26a10989bcab2d9c0a03d4c57ae78ba3d5c86"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/ndcurves-1.1.1"
    sha256 cellar: :any_skip_relocation, big_sur:      "a599bfbe24b97893ccee2fae8cb72b4806f36d2f1e88d6181ef787c5823c3e04"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "200721b312056f9d586231c6392ef777aa698949a5c0fc9266169c1259275875"
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
      project(Brewhpp-spline LANGUAGES CXX)
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
