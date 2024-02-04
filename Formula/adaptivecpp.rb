class Adaptivecpp < Formula
  desc "Implementation of SYCL and C++ standard parallelism for CPUs and GPUs"
  homepage "https://adaptivecpp.github.io"
  url "https://github.com/AdaptiveCpp/AdaptiveCpp.git", tag: "v23.10.0"
  license "BSD-2-Clause"
  head "https://github.com/AdaptiveCpp/AdaptiveCpp.git", branch: "develop"

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "llvm"

  def install
    ENV.prepend_path "PATH", Formula["llvm"].opt_bin
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    args = [
      "-DLLVM_ROOT=#{Formula["llvm"].opt_prefix}",
      "-DCMAKE_INSTALL_INCLUDEDIR=include",
      "-DWITH_ACCELERATED_CPU=ON",
      "-DWITH_CUDA_BACKEND=OFF",
      "-DWITH_ROCM_BACKEND=OFF",
      "-DWITH_LEVEL_ZERO_BACKEND=OFF",
      # Apple has deprecated OpenCL and trying to compile the OpenCL backend
      # results in lots of errors
      "-DWITH_OPENCL_BACKEND=OFF",
      # https://github.com/AdaptiveCpp/AdaptiveCpp/blob/develop/doc/stdpar.md
      # explains that currently only libstdc++ (gcc) is supported but libc++
      # (clang) is likely easy to add if there is enough demand; until it's
      # supported we need to disable it
      "-DWITH_STDPAR_COMPILER=OFF",
      "-DWITH_SSCP_COMPILER=ON",
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build", "-j"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"hello.cpp").write <<~EOS
      #include <sycl/sycl.hpp>
        int main(int argc, char* argv[]) {
        sycl::queue q;
        q.submit([&](sycl::handler& cgh) {
          auto os = sycl::stream{64, 64, cgh};
          cgh.single_task([=]() {
            os << "Hello, world!";
          });
        });
      }
    EOS
    # -O2 is needed to suppress a debug warning
    system "#{bin}/acpp", "-O2", "-o", "hello", "hello.cpp"
    assert_equal "Hello, world!", shell_output("./hello")
  end
end
