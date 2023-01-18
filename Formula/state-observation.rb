class StateObservation < Formula
  desc "Describes interfaces for state observers, and implements some observers"
  homepage "https://github.com/jrl-umi3218/state-observation/"
  url "https://github.com/jrl-umi3218/state-observation/releases/download/v1.5.0/state-observation-v1.5.0.tar.gz"
  sha256 "509529785a14459b48edd4943840add9315f1d947db1db6f79f7f7ef1ac02d99"
  license "BSD-2-Clause"
  revision 0

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/state-observation-1.5.0"
    sha256 cellar: :any,                 monterey:     "1a496acdc64a145f62ff3a8f0170194fee3db006c52293f5e25748c135ec130d"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ebcf0f3de3db66376c44b181c7fc6db28736711ef51625e1c58615c5354631d2"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "boost"
  depends_on "eigen"

  resource "test.cpp" do
    url "https://raw.githubusercontent.com/jrl-umi3218/state-observation/v1.4.1/unit-testings/test_acceleration_stabilization.cpp"
    sha256 "f10d373523eed1ea3908ab36383286bbc1ec9d77e867173e4b38c0181b16701d"
  end

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DBUILD_STATE_OBSERVATION_TOOLS:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource("test.cpp").stage testpath
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      set(CMAKE_CXX_STANDARD 11)
      project(Brewstate-observation LANGUAGES CXX)
      find_package(state-observation REQUIRED)
      add_executable(main test_acceleration_stabilization.cpp)
      target_link_libraries(main PUBLIC state-observation::state-observation)
    EOS
    # Avoid introducing march=native which will cause ABI breaks
    ENV["CXXFLAGS"] = ""
    system "cmake", ".", *std_cmake_args
    system "cmake", "--build", "."
    system "./main"
  end
end
