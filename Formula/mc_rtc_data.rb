class McRtcData < Formula
  desc "Data for the mc_rtc package"
  homepage "https://github.com/jrl-umi3218/mc_rtc_data"
  url "https://github.com/jrl-umi3218/mc_rtc_data/releases/download/v1.0.7/mc_rtc_data-v1.0.7.tar.gz"
  sha256 "a99e4dba0d35918212f716cfa1db127a60d0fa5d4f7aa9dda18503f6d614f747"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/mc_rtc_data-1.0.7"
    sha256 cellar: :any_skip_relocation, monterey:     "449ec7a99e9d1df22203f2d87bcd3c8f200047da45c7a7662f7904c60b460b2b"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "57cf575b77641da230c687535ab13562c37a9d61e900ca8ef6e7e4d5a695b556"
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
