class Tasks < Formula
  desc "Make real-time control for kinematics tree and list of kinematics tree"
  homepage "https://github.com/jrl-umi3218/Tasks/"
  url "https://github.com/jrl-umi3218/Tasks/releases/download/v1.4.0/Tasks-v1.4.0.tar.gz"
  sha256 "9693d2f47d0c7b0d99a7d8817c2dc34d9a3fedd48dca1a7b66927b63ac765e24"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/tasks-1.3.1_1"
    sha256 cellar: :any,                 catalina:     "f965bc47c9edbfa5bc179ca05881f7779edd932bf6de72ba5fdd7e160d4fb210"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "33435ffed7b2fbf864fb8f12fc25d5b83d46a953edd816b14df30f1de8775432"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "eigen-qld"
  depends_on "rbdyn"
  depends_on "sch-core-python"

  resource "arms.h" do
    url "https://raw.githubusercontent.com/jrl-umi3218/Tasks/v1.3.1/tests/arms.h"
    sha256 "af5869e0cd86b37d6235ada9e9ed74aec48723b834c1542374e61140846c6b6e"
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

    system Formula["python"].opt_bin/"python3", "-c", <<~EOS
      import tasks
      import tasks.qp as qp
    EOS
  end
end
