class EigenQuadprog < Formula
  desc "Allow to use the QuadProg QP solver with the Eigen3 library"
  homepage "https://github.com/jrl-umi3218/eigen-quadprog/"
  url "https://github.com/jrl-umi3218/eigen-quadprog/releases/download/v1.1.2/eigen-quadprog-v1.1.2.tar.gz"
  sha256 "521e9e8b0299891907697fcb9c76c1c53d8d0ed639e4f2e1277e70599ef26d3a"
  license "LGPL-3.0-only"

  bottle do
    root_url "https://github.com/mc-rtc/homebrew-mc-rtc/releases/download/eigen-quadprog-1.1.2"
    rebuild 1
    sha256 cellar: :any,                 monterey:     "db0b7529b6c1460250667a831c4c0b438bca82ecd830b60eb5ddabb2a8277643"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a147a730b818409633d42d5583c4c8410349c2b2f070d1daac3fd5a4a61d58b8"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "eigen"
  depends_on "gcc" # for gfortran

  def install
    ENV["HOMEBREW_ARCHFLAGS"] = "-march=#{Hardware.oldest_cpu}" unless build.bottle?

    args = std_cmake_args + %w[
      -DINSTALL_DOCUMENTATION:BOOL=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.1)
      project(BrewEigenQuadprog LANGUAGES CXX)
      find_package(eigen-quadprog REQUIRED)
      add_executable(main main.cpp)
      target_link_libraries(main PUBLIC eigen-quadprog::eigen-quadprog)
    EOS
    (testpath/"main.cpp").write <<~EOS
      #include <eigen-quadprog/QuadProg.h>

      #include <iostream>

      struct QP1
      {
        QP1()
        {
          nrvar = 6;
          nreq = 3;
          nrineq = 2;

          Q.resize(nrvar, nrvar);
          Aeq.resize(nreq, nrvar);
          Aineq.resize(nrineq, nrvar);
          A.resize(nreq + nrineq, nrvar);

          C.resize(nrvar);
          Beq.resize(nreq);
          Bineq.resize(nrineq);
          B.resize(nreq + nrineq);
          XL.resize(nrvar);
          XU.resize(nrvar);
          X.resize(nrvar);

          Aeq << 1., -1., 1., 0., 3., 1., -1., 0., -3., -4., 5., 6., 2., 5., 3., 0., 1., 0.;
          Beq << 1., 2., 3.;

          Aineq << 0., 1., 0., 1., 2., -1., -1., 0., 2., 1., 1., 0.;
          Bineq << -1., 2.5;

          A.topRows(nreq) = Aeq;
          A.bottomRows(nrineq) = -Aineq;

          B.head(nreq) = -Beq;
          B.tail(nrineq) = Bineq;

          // with  x between ci and cs:
          XL << -1000., -10000., 0., -1000., -1000., -1000.;
          XU << 10000., 100., 1.5, 100., 100., 1000.;

          // and minimize 0.5*x'*Q*x + p'*x with
          C << 1., 2., 3., 4., 5., 6.;
          Q.setIdentity();

          X << 1.7975426, -0.3381487, 0.1633880, -4.9884023, 0.6054943, -3.1155623;
        }

        int nrvar, nreq, nrineq;
        Eigen::MatrixXd Q, Aeq, Aineq, A;
        Eigen::VectorXd C, Beq, Bineq, B, XL, XU, X;
      };

      int main()
      {
        QP1 qp1;
        std::cout << "qp1.X: " << qp1.X.transpose() << "\\n";

        int nrineq = static_cast<int>(qp1.Aineq.rows());
        Eigen::QuadProgDense qp(qp1.nrvar, qp1.nreq, nrineq);

        qp.solve(qp1.Q, qp1.C,
          qp1.Aeq, qp1.Beq,
          qp1.Aineq, qp1.Bineq);

        std::cout << "qp.result(): " << qp.result().transpose() << "\\n";

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
