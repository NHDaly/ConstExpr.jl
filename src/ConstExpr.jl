module ConstExpr

export @constfunction, @constexpr

# Ideally all this logic would compile away, but for now we can turn it on/off with a debug flag.
macro constfunction(f)
    fname = f.args[1].args[1]
    fargs = f.args[1].args[2:end]
    fbody = f.args[2]
    escname = esc(fname)
    escargs = [esc(a) for a in fargs]
    escbody = esc(fbody)
    quote
        function f_inner($(escargs...))
            $escbody
        end
        function $escname(args...)
            val = f_inner(args...)
            # Ensure the inner function compiles away!
            #TODO: find the CORRECT method instance
            m = which(f_inner, typeof(args)).specializations.func
            #m.next()
            try
                @assert m.inferred_const === val
            catch UndefRefError
                @assert false "$($escname) failed to compile away to a Const!"
            end
            return val
        end
    end
end



macro constexpr(e)
    quote
        f_inner() = $(esc(e))
        begin
            val = f_inner()
            # Ensure the inner function compiles away!
            # Note that there will always only be one specialization, so this is fine.
            m = which(f_inner, ()).specializations.func
            try
                @assert m.inferred_const === val
            catch UndefRefError
                @assert false "Expr ($($(string(e)))) failed to compile away to a Const!"
            end
            val
        end
    end
end

end
