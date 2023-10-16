class Spacevecalg < Formula
  desc "Implementation of spatial vector algebra with the Eigen3 linear algebra library"
  homepage "https://github.com/jrl-umi3218/SpaceVecAlg"
  url "https://github.com/jrl-umi3218/SpaceVecAlg/releases/download/v1.2.5/SpaceVecAlg-v1.2.5.tar.gz"
  sha256 "a57ab3f594f49d4f247a0f5fb6422ae7d8583337b489b58a734b02c8489ed618"
  license "BSD-2-Clause"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/spacevecalg-1.2.5"
    sha256 cellar: :any_skip_relocation, monterey:     "2ba94604ce3b9dee48abe1c0f96c82ac6a91a7f523ea5e799c9f0d9606c8fb03"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "e2a32e8b2d07300ec26045b2f65fda63132f35ef03055faae2787a3696cf3f34"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"

  def install
    args = std_cmake_args + %w[
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
