using InteractiveUtils

@noinline child(i) = println(i)
parent(i) = child(i)

f = parent
tt = Tuple{Int}

# get the method instance
world = typemax(UInt)
meth = which(f, tt)
sig_tt = Tuple{typeof(f), tt.parameters...}
(ti, env) = ccall(:jl_type_intersection_with_env, Any,
                  (Any, Any), sig_tt, meth.sig)::Core.SimpleVector
meth = Base.func_for_method_checked(meth, ti)
linfo = ccall(:jl_specializations_get_linfo, Ref{Core.MethodInstance},
              (Any, Any, Any, UInt), meth, ti, env, world)

# generate IR
native_code = ccall(:jl_create_native, Ptr{Cvoid},
                    (Vector{Core.MethodInstance}, Base.CodegenParams),
                    [linfo], Base.CodegenParams())
mod_ref = ccall(:jl_get_llvm_module, Ptr{Cvoid}, (Ptr{Cvoid},), native_code)
@assert mod_ref != C_NULL
ccall(:jl_dump_llvm_module, Nothing, (Ptr{Cvoid},), mod_ref)

# get the top-level function index
api = Ref{UInt8}()
func_idx = Ref{UInt32}()
specfunc_idx = Ref{UInt32}()
ccall(:jl_get_function_id, Nothing,
      (Ptr{Cvoid}, Core.MethodInstance, Ptr{UInt8}, Ptr{UInt32}, Ptr{UInt32}),
      native_code, linfo, api, func_idx, specfunc_idx)

# get the top-level function
func_ref = ccall(:jl_get_llvm_function, Ptr{Cvoid},
                 (Ptr{Cvoid}, UInt32),
                 native_code, func_idx[])
ccall(:jl_dump_llvm_value, Nothing, (Ptr{Cvoid},), func_ref)
specfunc_ref = ccall(:jl_get_llvm_function, Ptr{Cvoid},
                     (Ptr{Cvoid}, UInt32),
                     native_code, specfunc_idx[])
ccall(:jl_dump_llvm_value, Nothing, (Ptr{Cvoid},), specfunc_ref)
