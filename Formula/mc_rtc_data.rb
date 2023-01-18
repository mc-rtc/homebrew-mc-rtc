class McRtcData < Formula
  desc "Data for the mc_rtc package"
  homepage "https://github.com/jrl-umi3218/mc_rtc_data"
  url "https://github.com/jrl-umi3218/mc_rtc_data/releases/download/v1.0.6/mc_rtc_data-v1.0.6.tar.gz"
  sha256 "d53821c750491e0d001923fbed8f414fb6071a85913f300d21d1fdd18689b341"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/mc_rtc_data-1.0.6"
    sha256 cellar: :any_skip_relocation, monterey:     "8181982240cd6ae85ea1170464b83a867dc5064d88449c31c7971276cc6d59b5"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "b58418118e28c17b0196506a86c4eb90753501ee327bc235c42e5c944325691e"
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
