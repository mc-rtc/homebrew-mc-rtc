class McRtc < Formula
  desc "Interface for simulated and real robotic systems suitable for real-time control"
  homepage "https://jrl-umi3218.github.io/mc_rtc/"
  url "https://github.com/jrl-umi3218/mc_rtc/releases/download/v1.7.0/mc_rtc-v1.7.0.tar.gz"
  sha256 "382fb4bc67c03f446ff59b1c60cfe28125571fc64883bca879028788f3c38428"
  license "BSD-2-Clause"
  revision 1

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/mc_rtc-1.7.0_1"
    sha256 catalina:     "9543ed78a88e20694007b603dd64a8d6c8f1a4ffa84fec39caf19296d1ff7fd7"
    sha256 x86_64_linux: "ab5d3760c4564587f2b4c0a0674d89ef71fa8c1c835e3fc717c4883b85a168ad"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "cython" => :build
  depends_on "eigen-quadprog"
  depends_on "geos"
  depends_on "hpp-spline"
  depends_on "libtool"
  depends_on "mc_rbdyn_urdf"
  depends_on "mc_rtc_data"
  depends_on "nanomsg"
  depends_on "spdlog"
  depends_on "state-observation"
  depends_on "tasks"

  def install
    xy = Language::Python.major_minor_version Formula["python"].opt_bin/"python3"
    ENV.prepend_create_path "PYTHONPATH", Formula["cython"].opt_libexec/"lib/python#{xy}/site-packages"

    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    inreplace "cmake/cython/cython.cmake",
              "set(PIP_EXTRA_OPTIONS --target \"${PIP_TARGET}\")",
              "set(PIP_EXTRA_OPTIONS --prefix \"${PIP_INSTALL_PREFIX}\")"

    args = std_cmake_args + %W[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DMC_LOG_UI_PYTHON_EXECUTABLE=#{Formula["python"].opt_bin/"python3"}
      -DPIP_INSTALL_PREFIX=#{prefix}
      -DPYTHON_BINDING_FORCE_PYTHON3:BOOL=ON
      -DDISABLE_ROS:BOOL=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(Brewmc_rtc LANGUAGES CXX)
      find_package(mc_rtc REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC mc_rtc::mc_control)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <mc_control/mc_global_controller.h>
      #include <mc_rtc/version.h>

      int main()
      {
        mc_rtc::log::info("mc_rtc compilation version: {}", mc_rtc::MC_RTC_VERSION);
        mc_rtc::log::info("mc_rtc library version: {}", mc_rtc::version());
        mc_rtc::Configuration config;
        config.add("LogDirectory", "#{testpath}");
        config.save("#{testpath}/mc_rtc.yaml");
        mc_control::MCGlobalController controller("#{testpath}/mc_rtc.yaml");
        // Simple init
        const auto & mb = controller.robot().mb();
        const auto & mbc = controller.robot().mbc();
        const auto & rjo = controller.ref_joint_order();
        std::vector<double> initq;
        for(const auto & jn : rjo)
        {
          for(const auto & qi : mbc.q[static_cast<unsigned int>(mb.jointIndexByName(jn))])
          {
            initq.push_back(qi);
          }
        }

        std::vector<double> qEnc(initq.size(), 0);
        std::vector<double> alphaEnc(initq.size(), 0);
        auto simulateSensors = [&, qEnc, alphaEnc]() mutable {
          auto & robot = controller.robot();
          for(unsigned i = 0; i < robot.refJointOrder().size(); i++)
          {
            auto jIdx = robot.jointIndexInMBC(i);
            if(jIdx != -1)
            {
              auto jointIndex = static_cast<unsigned>(jIdx);
              qEnc[i] = robot.mbc().q[jointIndex][0];
              alphaEnc[i] = robot.mbc().alpha[jointIndex][0];
            }
          }
          controller.setEncoderValues(qEnc);
          controller.setEncoderVelocities(alphaEnc);
          controller.setSensorPositions({{"FloatingBase", robot.posW().translation()}});
          controller.setSensorOrientations({{"FloatingBase", Eigen::Quaterniond{robot.posW().rotation()}}});
        };

        controller.setEncoderValues(qEnc);
        controller.init(initq, controller.robot().module().default_attitude());
        controller.running = true;
        for(size_t i = 0; i < 1000; ++i)
        {
          simulateSensors();
          controller.run();
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
      import mc_rbdyn
      import mc_control
    EOS
  end
end
