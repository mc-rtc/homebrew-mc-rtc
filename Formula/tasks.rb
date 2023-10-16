class Tasks < Formula
  desc "Make real-time control for kinematics tree and list of kinematics tree"
  homepage "https://github.com/jrl-umi3218/Tasks/"
  url "https://github.com/jrl-umi3218/Tasks/releases/download/v1.8.0/Tasks-v1.8.0.tar.gz"
  sha256 "b89bdbcace7cd670163004de1bc727640ccb49f59433353370b3fe960d6c07cf"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/tasks-1.8.0"
    rebuild 1
    sha256 cellar: :any,                 monterey:     "54cf3dcf5b42d74b2c1631d0e3bf69b9943c70e2f5b5d77579edb063de84dc57"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "96ad747fa2b1692f486b030415df370990a3ebde8262088da62b45e65eb6f7e8"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen-qld"
  depends_on "rbdyn"
  depends_on "sch-core"

  resource "arms.h" do
    url "https://raw.githubusercontent.com/jrl-umi3218/Tasks/v1.3.1/tests/arms.h"
    sha256 "af5869e0cd86b37d6235ada9e9ed74aec48723b834c1542374e61140846c6b6e"
  end

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    inreplace "cmake/cython/cython.cmake",
              "set(PIP_EXTRA_OPTIONS --target \"${PIP_TARGET}\")",
              "set(PIP_EXTRA_OPTIONS --prefix \"${PIP_INSTALL_PREFIX}\")"

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPYTHON_BINDING:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource("arms.h").stage testpath

    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewTasks LANGUAGES CXX)
      find_package(Tasks REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC Tasks::Tasks)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <RBDyn/EulerIntegration.h>
      #include <RBDyn/FK.h>
      #include <RBDyn/FV.h>

      #include <Tasks/QPSolver.h>
      #include <Tasks/QPTasks.h>

      #include "arms.h"

      int main()
      {
        using namespace Eigen;
        using namespace sva;
        using namespace rbd;
        using namespace tasks;

        MultiBody mb;
        MultiBodyConfig mbcInit;

        std::tie(mb, mbcInit) = makeZXZArm();

        std::vector<MultiBody> mbs = {mb};
        std::vector<MultiBodyConfig> mbcs(1);

        forwardKinematics(mb, mbcInit);
        forwardVelocity(mb, mbcInit);

        qp::QPSolver solver;

        solver.nrVars(mbs, {}, {});

        solver.updateConstrSize();

        Vector3d posD = Vector3d(0.707106, 0.707106, 0.);
        qp::PositionTask posTask(mbs, 0, "b3", posD);
        qp::SetPointTask posTaskSp(mbs, 0, &posTask, 10., 1.);

        // Test addTask
        solver.addTask(&posTaskSp);

        // Test PositionTask
        mbcs[0] = mbcInit;
        for(int i = 0; i < 10000; ++i)
        {
          solver.solve(mbs, mbcs);
          eulerIntegration(mb, mbcs[0], 0.001);

          forwardKinematics(mb, mbcs[0]);
          forwardVelocity(mb, mbcs[0]);
        }

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
