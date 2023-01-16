class Spacevecalg < Formula
  desc "Implementation of spatial vector algebra with the Eigen3 linear algebra library"
  homepage "https://github.com/jrl-umi3218/SpaceVecAlg"
  url "https://github.com/jrl-umi3218/SpaceVecAlg/releases/download/v1.2.1/SpaceVecAlg-v1.2.1.tar.gz"
  sha256 "6eea01222db773f5f6e53b96f4a03b4918bd208b91b3c4186c6c56ee50fed21d"
  license "BSD-2-Clause"
  revision 2

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/spacevecalg-1.2.1_1"
    sha256 cellar: :any_skip_relocation, big_sur:      "468531e8a4a82e93ec70551f2018f2544f0ed68ec64a2f0966c9398cc9b538e7"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "dc8d93eae77f4075d7254e9cfbe1a7c396d033019ca4710648020504cfa46515"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"

  def install
    args = std_cmake_args + %W[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
      -DPYTHON_BINDING:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewSpaceVecAlg LANGUAGES CXX)
      find_package(SpaceVecAlg REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC SpaceVecAlg::SpaceVecAlg)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <SpaceVecAlg/SpaceVecAlg>
      #include <iostream>

      int main() {
        auto pt = sva::PTransformd::Identity();
        std::cout << pt.rotation() << "\\n" << pt.translation().transpose() << "\\n";
        return 0;
      }
    EOS
    system "cmake", ".", *std_cmake_args
    system "make"
    system "./main"
  end
end
