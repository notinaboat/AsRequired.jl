"""
# As Required - A System for Requirements Tracing 

The As Required system defines a simple notation for specifying
requirements and verifying that they are covered by appropriate
design documentation and tests.

The system does not require the use of any particular documentation
system. Documentation could be written in word processor, a
spreadsheet, a wiki, a plain text file or a source code comment.
As long as the notation is is used consistently throughout the relevant
documents, the system can extract the information it needs to build
a requirements tracing matrix.


# Basic Requirements Notation

Specification of a Requirement uses the `:` symbol like this:

> [**R123**:] The Widget is blue.
>
> [**R124**:] The Widget is waterproof.


Design Specifications and Test Specifications are defined the same way:

> [**D7**:] The Widget is painted with Acme Paint colour `#0000FF`.
>
> [**D8**:] The Widget's enclosure is sealed by o-rings.
>
> [**T11**:] Immerse the widget in 1m of water for 5 minutes...


Relationships are defined using the `=>` symbol. e.g. if design
specification  **D7** covers requirement **R123** we write:

> [**D7**=>**R123**]

If the context is implied, the left hand side of the relationship
can be omitted.  e.g. In the following case, "[=>**R124**]" occurs
in the specification of **D8** so it means that **D8** covers
requirement **R124**:

> [**D8**:] The Widget's enclosure is sealed by o-rings [=>**R124**].

Test coverage is defined the same way:

> [**T11**:] Immerse the widget in 1m of water for 5 minutes... [=>**R124**].


# Partial Specifications

Sometimes a specification requires further refinement. An incomplete
specification is defined using the `?=` symbol like this:

> [**R5**:] The Widget prevents unauthorised access.
> 
> [**D10**?=] The Widget has a Combination Lock [=>**R5**].


This means that the design is not complete until another
design specification is defined to cover the detail of **D10**. e.g.

> [**D1001**:] The lock has at least 1000 combinations. [=>**D10**]
> 
> [**D1002**:] The lock is tamper proof to standard XXXXXX. [=>**D10**]

The system will consider the design to be complete if at least one
item is annotated with [=>**D10**]. In this case there are two
detailed specifications that cover **D10**. A design review will
have to decide if the two detailed specifications together are
enough to cover **D10**. The system cannot automatically determine that
a third detailed specification might be needed.

Finer control over detailed specifications can be achieved by using
intermediate partial specifications like this:

> [**D10**?=] The Widget has a Combination Lock [=>**R5**].
>  * [**D101**?=] The lock has a combination that is difficult to guess. [=>**D10**]
>  * [**D102**?=] The lock detects repeated attempts to gutess the combination. [=>**D10**]
>  * [**D103**?=] The lock is difficult to break without special tools. [=>**D10**]
>
> [**D1001**:] The lock has at least 1000 combinations. [=>**D101**]
> 
> [**D1002**:] The lock is tamper proof to standard XXXXXX. [=>**D103**]

Now the system will not consider the design to be complete because **D102**
is not covered by a more detailed specification.


# Markdown Integration

When the notation is used in a Markdown document, the special `@req` link
target can be used to create links to the trace matrix. e.g.

    [D10?=](@req) The Widget has a Combination Lock [=>R5](@req).

The `[D10?=]` link or the `[=>R5]` link will take the reader to the relevant
row in the trace matrix.

<a id="foo"/>[RXXX](@req)


# Coverage Rules

By default As Required implements the following coverage rules.

Rules can be altered by modifying the `AsRequired.coverage_rules` Dict.

--------------------------------------------------------------------------------
Type  Description                 Rule
----- --------------------------  ----------------------------------------------
HXXX  Hazard (Risk)               `[RXX=>HXX]`: Every Hazard must be covered by a
                                  Requirement Specification for a Risk Control.

RXXX  Requirement Specification   `[DXX=>RXX]`: Every Requirement
                                  must be covered by a Design Specification.

DXXX  Design Specification        `[UXX=>DXX]`, `[TXX=>DXX]`: Every Design
                                  Specification must convered by a Unit Test
                                  and a System Test.

UXXX  Unit Test                   `[ULXX=>UXX]`: Every Unit Test must be covered
                                  by a Unit Test Log.

TXXX  System Test                 `[TRXX=>TXX]`: Every Test must be covered by
                                  a Test Record.
--------------------------------------------------------------------------------
"""
module AsRequired

using ReadmeDocs
using Markdown
using DataStructures
using LazyJSON

global rule_names =
OrderedDict(
    "H"  => "Hazard",
    "R"  => "Requirement Specification",
    "T"  => "Test Protocol",
    "TR" => "Test Record",
    "D"  => "Design Specification",
    "U"  => "Unit Test",
    "UR" => "Unit Test Record",
    "I"  => "Implementation"
)


global requirement_rules =
OrderedDict(
    "H" => ["R"],
    "R" => ["T"],
    "T" => ["TR"],
    "TR" => [],
)

global design_rules = 
OrderedDict(
    "R" => ["D"],
    "D" => ["I", "U", "T"],
    "I" => [],
    "U" => ["UR"],
    "UR" => [],
    "T" => ["TR"],
    "TR" => []
)


README"""
    extract_tags(string)

Extract requirements tracing tags from `string`.
"""
function extract_tags(data)
    tags = []
    left, op, right = nothing, nothing, nothing
    for m in eachmatch(r"""
                       \[

                       [*]*

                       ( [A-Z] [A-Z0-9]{0,2} [0-9.]{0,8} ) ?

                       [*]*

                       [ ]?

                       (?| (:)
                         | (=>) )

                       [ ]?

                       ( [A-Z] [A-Z0-9]{1,2} [0-9.]{0,8} ) ?

                       \]
                       """x, data)
        old_left = left
        left, op, right = m[1], m[2], m[3]
        if left == nothing
            left = old_left
        end
        push!(tags, (left, op, right))
        old_left = left
    end
    return tags
end


remove_tags(data) = replace(data, r"\[[^\]]*\](\([^)]*\))?" => "") |> 
                    x -> replace(x, r"\\$" => "") |> 
                    strip


tag_type(tag) = match(r"([A-Z]*)", tag)[1]
tag_id(tag) = match(r"[A-Z]*(.*)", tag)[1]


function scan_file(f)
    definitions = OrderedDict()
    relationships = []
    old_l = nothing
    for (i, line) in enumerate(eachline(f))
        for (l, op, r) in extract_tags(line)
            if isnothing(l)
                l = old_l
            end
            if isnothing(l)
                @warn "Can't find left hand side for $op $r"
            else
                if tag_id(l) == ""
                    l = "$l:$f:$i"
                    definitions[l] = (i, remove_tags(line))
                end
                @info "$l $op $r"
                if op == ":"
                    if l ∈ keys(definitions)
                        @warn "Duplicate $f:$i:$l ($(definitions[l]))"
                    else
                        definitions[l] = (i, remove_tags(line))
                    end
                elseif op == "=>"
                    push!(relationships, l => r)
                end
            end
            old_l = l
        end
    end
    definitions, relationships
end

function scan_files(l...)
    definitions = OrderedDict()
    relationships = []
    for f in l
        d, r = scan_file(f)
        for (tag, (line_no, context)) in d
            @assert l ∉ keys(definitions)
            definitions[tag] = (f, line_no, context)
        end
        append!(relationships, r)
    end
    definitions, relationships
end


function coverage_match(coverage_type, relationship, target)
    c, t = relationship
    coverage_type == tag_type(c) && t == target
end


function assess_coverage(target, relationships, rules)

    result = OrderedDict();
    for rule in rules[tag_type(target)]
        l = first.(filter(x->coverage_match(rule, x, target), relationships))
        result[rule] = l 
    end
    return result
end


function coverage_rows(prefix, target, relationships, rules)
    if isempty(rules[tag_type(target)])
        return [[prefix..., target]]
    end
    result = []
    for (ctype, citems) in assess_coverage(target, relationships, rules)
        if isempty(citems)
            push!(result, [prefix..., target, "$ctype? ⚠️"])
        else
            for i in citems
                for r in coverage_rows([prefix..., target], i, relationships, rules)
                    push!(result, r)
                end
            end
        end
    end
    #@info "prefix:$prefix $target => $result"
    return result
end


function coverage_table(definitions, relationships, rules)
    rows = []
    done = Set()
    columns = collect(keys(rules))
    header = [rule_names[k] for k in columns]
    for k in columns
        for d in keys(definitions)
            if d ∉ done && tag_type(d) == k
                for r in coverage_rows([], d, relationships, rules)
                    out_row = []
                    for c in columns
                        x = ""
                        for i in r
                            if startswith(i, c)
                                x = i
                                break
                            end
                        end
                        md = "<a name=\"$x\"></a>"
                        if x ∈ keys(definitions) && c ∈ ["H", "R", "D", "T"]
                            file, line, txt = definitions[x]
                            x = "[$x: $txt]($file#$x)"
                        end
                        if x ∈ keys(definitions) && c ∈ ["I"]
                            t, f, n = split(x, ":")
                            file, line, txt = definitions[x]
                            x = "[$(basename(f)):$n $txt]($file#cb-$n)"
                        end
                        md *= x
                        push!(out_row, md)
                    end
                    push!(rows, out_row)
                    push!(done, r...)
                end
                push!(done, d)
            end
        end
    end

    return [header, rows...]
end

function md_coverage_table(definitions, relationships, rules)
    data = coverage_table(definitions, relationships, rules)
    Markdown.Table(data, fill(:l, length(data[1])))
end


function md_coverage_table()

    d, r = scan_files(ARGS...)

    rt = md_coverage_table(d, r, requirement_rules)
    dt = md_coverage_table(d, r, design_rules)

    println(md"""
        # Requirements Trace Report

        ## Requirements Tracing Rules

        $rt


        ## Design Tracing Rules
        
        $dt
        
        """)
end



#=
lua filter 

function Link(el)

    el.attr = {id = 'foo'}
end
=#


function pandoc_filter()
    data = read(stdin, String)
    pandoc = LazyJSON.value(data)
    for (t, c) in pandoc["blocks"]
        if t == "Para"
            for i in x
                @show i
            end
        end
    end
#    write(stdout, data)
end

end # module
