class McRtc < Formula
  desc "Interface for simulated and real robotic systems suitable for real-time control"
  homepage "https://jrl-umi3218.github.io/mc_rtc/"
  url "https://github.com/jrl-umi3218/mc_rtc/releases/download/v2.0.0/mc_rtc-v2.0.0.tar.gz"
  sha256 "0bb6fa25c8b0aeff9c67a75f66e4fb2d34c782b66511c4d93aa290a0cf0e1526"
  license "BSD-2-Clause"
  revision 1

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/mc_rtc-1.11.0"
    sha256 x86_64_linux: "c90c6c02f8cc75c5964fe6b8e006bce09e7613f96739782ad61c1344f7a54624"
  end

  depends_on "cmake"
  depends_on "eigen-quadprog"
  depends_on "geos"
  depends_on "libnotify"
  depends_on "libtool"
  depends_on "mc_rtc_data"
  depends_on "nanomsg"
  depends_on "ndcurves"
  depends_on "pkg-config"
  depends_on "python"
  depends_on "spdlog"
  depends_on "state-observation"
  depends_on "tasks"
  depends_on "tvm"

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %W[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DMC_LOG_UI_PYTHON_EXECUTABLE=#{Formula["python"].opt_bin/"python3"}
      -DPIP_INSTALL_PREFIX=#{prefix}
      -DPYTHON_BINDING:BOOL=OFF
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
  end
end
