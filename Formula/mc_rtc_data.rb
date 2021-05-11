class McRtcData < Formula
  desc "Data for the mc_rtc package"
  homepage "https://github.com/jrl-umi3218/mc_rtc_data"
  url "https://github.com/jrl-umi3218/mc_rtc_data/releases/download/v1.0.4/mc_rtc_data-v1.0.4.tar.gz"
  sha256 "682c0bff88970668567c9f06f5bfad57032b48ba488e66ae5466b31d49b77f3f"
  license "BSD-2-Clause"

  depends_on "cmake" => [:build, :test]

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewMcRtcData LANGUAGES CXX)
      find_package(jvrc_description REQUIRED)
      message("jvrc_description_INSTALL_PREFIX ${jvrc_description_INSTALL_PREFIX}")
      find_package(mc_env_description REQUIRED)
      message("mc_env_description_INSTALL_PREFIX ${mc_env_description_INSTALL_PREFIX}")
      find_package(mc_int_obj_description REQUIRED)
      message("mc_int_obj_description_INSTALL_PREFIX ${mc_int_obj_description_INSTALL_PREFIX}")
    EOS
    system "cmake", ".", *std_cmake_args
  end
end
