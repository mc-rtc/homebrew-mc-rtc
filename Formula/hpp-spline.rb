class HppSpline < Formula
  desc "Library for creating smooth cubic splines"
  homepage "https://github.com/humanoid-path-planner/hpp-spline/"
  url "https://github.com/gergondet/hpp-spline/releases/download/v4.8.3/hpp-spline-4.8.3.tar.gz"
  sha256 "4a96ec81777befce539f649fa09ddf10f479e49adbe532b2599bba945655dea1"
  license ""

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DBUILD_PYTHON_INTERFACE:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(Brewhpp-spline LANGUAGES CXX)
      find_package(hpp-spline REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC hpp-spline::hpp-spline)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <hpp/spline/exact_cubic.h>
      #include <hpp/spline/bezier_curve.h>
      #include <hpp/spline/polynom.h>
      #include <hpp/spline/spline_deriv_constraint.h>
      #include <hpp/spline/helpers/effector_spline.h>
      #include <hpp/spline/helpers/effector_spline_rotation.h>
      #include <hpp/spline/bezier_polynom_conversion.h>

      typedef std::pair<double, Eigen::Vector3d> Waypoint;
      typedef std::vector<Waypoint> T_Waypoint;

      // loading helper class namespace
      using namespace spline::helpers;

      int main()
      {
        // Create waypoints
        T_Waypoint waypoints;
        waypoints.push_back(std::make_pair(0., Eigen::Vector3d(0,0,0)));
        waypoints.push_back(std::make_pair(1., Eigen::Vector3d(0.5,0.5,0.5)));
        waypoints.push_back(std::make_pair(2., Eigen::Vector3d(1,1,0)));

        exact_cubic_t* eff_traj = effector_spline(waypoints.begin(),waypoints.end());

        // evaluate spline
        (*eff_traj)(0.); // (0,0,0)
        (*eff_traj)(2.); // (1,1,0)

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
