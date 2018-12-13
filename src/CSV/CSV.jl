module CSV
const TypeVec = Vector{DataType}
# ============================================================================ #
mutable struct Row{T<:AbstractString}
    data::T
    delim::Char
end
# ---------------------------------------------------------------------------- #
Base.iterate(r::Row) = iterate(r, 1)
# ---------------------------------------------------------------------------- #
function Base.iterate(r::Row, klast::Int)
    (klast > length(r.data) || klast < 1) && return nothing

    while klast < length(r.data) && isspace(r.data[klast])
        klast += 1
    end

    if r.data[klast] == '"'
        # find the next '"' that is not escaped (preceded by a '\')
        k = search(r.data, '"', klast+1)
        while r.data[k-1] == '\\'
            k = search(r.data, '"', k+1)
        end

        # k points to the char after the closing '"'
        k += 1

        # knext needs to point to the char after the closing r.delim or 0
        knext = search(r.data, r.delim, k)
        knext = knext != nothing ? knext + 1 : 0
    else
        # element is not quoted, simply find the next delim
        k = search(r.data, r.delim, klast)
        if k == nothing
            knext = 0
            k = length(r.data) + 1
        elseif k == length(r.data)
            # string ends with delim (i.e. last element of this row is empty)
            knext = 0
        else
            knext = k + 1
        end
    end
    return SubString(r.data, klast, k-1), knext
end
# ---------------------------------------------------------------------------- #
Base.IteratorSize(r::Row) = SizeUnknown()
Base.IteratorEltype(r::Row) = HasEltype()
Base.eltype(r::Row{T}) where T = T
# ---------------------------------------------------------------------------- #
# function Base.collect(r::Row)
#     out = Vector{String}()
#     for x in r
#         push!(out, x)
#     end
#     return out
# end
@inline search(x::AbstractString, y::Char, k::Integer) = findnext(a->a==y, x, k)
# ============================================================================ #
function parse(ifile::String, delim::Char=',', types::TypeVec=TypeVec())
    lines = split(read(ifile, String), r"\n|\r\n|\r", limit=0, keepempty=false)
    hdr = split_line(lines[1], delim)
    if isempty(types)
        types = fill(Any, length(hdr))
    elseif length(types) < length(hdr)
        append!(types, fill(Any, length(hdr) - length(types)))
    end

    data = Dict{String, Vector}(
        hdr[k] => Vector{types[k]}(undef, length(lines)-1) for k in 1:length(hdr)
    )

    for k = 2:length(lines)
        j = 1
        for item in Row(lines[k], delim)
            data[hdr[j]][k-1] = parse_item(types[j], item)
            j += 1
        end
    end
    return data
end
# ============================================================================ #
isquoted(str::AbstractString) = occursin(r"^\"((?:[^\"\\]|\\.)*)\"$", strip(str))
# ============================================================================ #
dequote(str::AbstractString) = replace(str, r"(?:^\s*\")|(?:\"\s*$)"=>"")
# ============================================================================ #
function split_line(str::AbstractString, delim::Char)
    out = Vector{String}()
    for x in Row(str, delim)
        push!(out, dequote(x))
    end
    return out
end
# ============================================================================ #
parse_item(::Type{T}, item::AbstractString) where T<:Number =
    Base.parse(T, strip(item))
# ============================================================================ #
function parse_item(::Type, item::AbstractString)
    if isquoted(item)
        return dequote(item)
    else
        return strip(item)
    end
end
# ============================================================================ #
end
