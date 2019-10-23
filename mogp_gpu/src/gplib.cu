#include <cmath>
#include <iostream>
#include <cuda_runtime.h>
#include <cublas_v2.h>
#include "gp_gpu.hpp"

struct gplib_handle {
    int status;
    DenseGP_GPU *gp;
    std::string message;
};

extern "C" {

    double gplib_hello_world(void)
    {
        return 0.1134;
    }

    // Return an error code from the last operation performed
    int gplib_status(void *handle) {
        return static_cast<gplib_handle *>(handle)->status;
    }

    // if the status was non-zero, return a pointer to a c-string
    // corresponding to the error
    const char *gplib_error_string(void *handle) {
        return static_cast<gplib_handle *>(handle)->message.c_str();
    }

    void *gplib_make_gp(unsigned int N, unsigned int Ninput,
                        const double *theta, const double *xs, const double *ts,
                        const double *Q, const double *invQ,
                        const double *invQt)
    {
        // size_t free, total;
        // cudaMemGetInfo(&free, &total);

        auto handle = new gplib_handle;
        try {
            auto gp = new DenseGP_GPU(N, Ninput, theta, xs, ts, Q, invQ, invQt);
            handle->gp = gp;
            handle->status = 0;
        } catch(const std::exception& e) {
            handle->status = 1;
            handle->gp = nullptr;
            handle->message = e.what();
        }
        return handle;
    }
    
    void gplib_destroy_gp(void *handle)
    {
        gplib_handle *h = static_cast<gplib_handle *>(handle);
        if (h) {
            if (h->gp) delete h->gp;
            delete h;
        }
    }
    
    double gplib_predict(void *handle, double *xs)
    {
        gplib_handle *h = static_cast<gplib_handle *>(handle);
        try {
            double result = h->gp->predict(xs);
            h->status = 0;
            return result;
        } catch (const std::exception& e) {
            h->status = 1;
            h->message = e.what();
            return nan("");
        }
    }

    void gplib_update_theta(void *handle, const double *invQ,
                            const double *theta, const double *invQt)
    {
        gplib_handle *h = static_cast<gplib_handle *>(handle);
        try {
            h->gp->update_theta(invQ, theta, invQt);
            h->status = 0;
        } catch (const std::exception& e) {
            h->status = 1;
            h->message = e.what();           
        }
    }
    
// double gplib_predict_batch(void *handle, int Nnew, double *xs, double *result)
// {
//     return gp->predict
// }

} // extern "C"