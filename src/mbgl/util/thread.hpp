#ifndef MBGL_UTIL_THREAD
#define MBGL_UTIL_THREAD

#include <future>
#include <thread>
#include <functional>

#include <mbgl/util/run_loop.hpp>

namespace {

template <::std::size_t...>
struct index_sequence {};

template <::std::size_t N, ::std::size_t... I>
struct integer_sequence : integer_sequence<N - 1, N - 1, I...> {};

template <::std::size_t... I>
struct integer_sequence<0, I...> {
    using type = index_sequence<I...>;
};

}

namespace mbgl {
namespace util {

// Manages a thread with Object.

// Upon creation of this object, it launches a thread, creates an object of type Object in that
// thread, and then calls .start(); on that object. When the Thread<> object is destructed, the
// Object's .stop() function is called, and the destructor waits for thread termination. The
// Thread<> constructor blocks until the thread and the Object are fully created, so after the
// object creation, it's safe to obtain the Object stored in this thread.

template <class Object>
class Thread {
public:
    template <class... Args>
    Thread(const std::string& name, Args&&... args);
    ~Thread();

    // Invoke object->fn(args...) in the runloop thread.
    template <typename Fn, class... Args>
    void invoke(Fn fn, Args&&... args) {
        loop->invoke(std::bind(fn, object, args...));
    }

    // Invoke object->fn(args...) in the runloop thread, then invoke callback(result) in the current thread.
    template <typename Fn, class R, class... Args>
    void invokeWithResult(Fn fn, std::function<void (R)> callback, Args&&... args) {
        loop->invokeWithResult(std::bind(fn, object, args...), callback);
    }

    uv_loop_t* get() { return loop->get(); }

private:
    Thread(const Thread&) = delete;
    Thread(Thread&&) = delete;
    Thread& operator=(const Thread&) = delete;
    Thread& operator=(Thread&&) = delete;

    template <typename P, std::size_t... I>
    void run(P&& params, index_sequence<I...>);

    std::promise<void> running;
    std::promise<void> joinable;

    std::thread thread;

    Object* object;
    RunLoop* loop;
};

template <class Object>
template <class... Args>
Thread<Object>::Thread(const std::string& name, Args&&... args) {
    // Note: We're using std::tuple<> to store the arguments because GCC 4.9 has a bug
    // when expanding parameters packs captured in lambdas.
    std::tuple<Args...> params = std::forward_as_tuple(::std::forward<Args>(args)...);

    thread = std::thread([&] {
        #ifdef __APPLE__
        pthread_setname_np(name.c_str());
        #else
        (void(name));
        #endif

        constexpr auto seq = typename integer_sequence<sizeof...(Args)>::type();
        run(std::move(params), seq);
    });

    running.get_future().get();
}

template <class Object>
template <typename P, std::size_t... I>
void Thread<Object>::run(P&& params, index_sequence<I...>) {
    Object object_(std::get<I>(std::forward<P>(params))...);
    object = &object_;

    RunLoop loop_;
    loop = &loop_;

    running.set_value();
    loop_.run();

    joinable.get_future().get();
}

template <class Object>
Thread<Object>::~Thread() {
    loop->stop();
    joinable.set_value();
    thread.join();
}

}
}

#endif
