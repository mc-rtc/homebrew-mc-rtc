class McRtcData < Formula
  desc "Data for the mc_rtc package"
  homepage "https://github.com/jrl-umi3218/mc_rtc_data"
  url "https://github.com/jrl-umi3218/mc_rtc_data/releases/download/v1.0.4/mc_rtc_data-v1.0.4.tar.gz"
  sha256 "682c0bff88970668567c9f06f5bfad57032b48ba488e66ae5466b31d49b77f3f"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/mc_rtc_data-1.0.4"
    sha256 cellar: :any_skip_relocation, catalina:     "19776a56170605ee5e79365cd6d6220fe684d75ba7bf50dc0f32db3ae5ccb6b5"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "f3ad769db551b0911df9e779daef4225e6da1d36661a7fa137cc0b179e35706a"
  end

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
