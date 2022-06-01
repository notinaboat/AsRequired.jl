# As Required - A System for Requirements Tracing

The As Required system defines a simple notation for specifying requirements and verifying that they are covered by appropriate design documentation and tests.

The system does not require the use of any particular documentation system. Documentation could be written in word processor, a spreadsheet, a wiki, a plain text file or a source code comment. As long as the notation is is used consistently throughout the relevant documents, the system can extract the information it needs to build a requirements tracing matrix.

# Basic Requirements Notation

Specification of a Requirement uses the `:=` symbol like this:

> [**R123**:=] The Widget is blue.
>
> [**R124**:=] The Widget is waterproof.


Design Specifications and Test Specifications are defined the same way:

> [**D7**:=] The Widget is painted with Acme Paint colour `#0000FF`.
>
> [**D8**:=] The Widget's enclosure is sealed by o-rings.
>
> [**T11**:=] Immerse the widget in 1m of water for 5 minutes...


Relationships are defined using the `=>` symbol. e.g. if design specification  **D7** covers requirement **R123** we write:

> [**D7**=>**R123**]


If the context is implied, the left hand side of the relationship can be omitted.  e.g. In the following case, "[=>**R124**]" occurs in the specification of **D8** so it means that **D8** covers requirement **R124**:

> [**D8**:=] The Widget's enclosure is sealed by o-rings [=>**R124**].


Test coverage is defined the same way:

> [**T11**:=] Immerse the widget in 1m of water for 5 minutes... [=>**R124**].


# Partial Specifications

Sometimes a specification requires further refinement. An incomplete specification is defined using the `?=` symbol like this:

> [**R5**:=] The Widget prevents unauthorised access.
>
> [**D10**?=] The Widget has a Combination Lock [=>**R5**].


This means that the design is not complete until another design specification is defined to cover the detail of **D10**. e.g.

> [**D1001**:=] The lock has at least 1000 combinations. [=>**D10**]
>
> [**D1002**:=] The lock is tamper proof to standard XXXXXX. [=>**D10**]


The system will consider the design to be complete if at least one item is annotated with [=>**D10**]. In this case there are two detailed specifications that cover **D10**. A design review will have to decide if the two detailed specifications together are enough to cover **D10**. The system cannot automatically determine that a third detailed specification might be needed.

Finer control over details specifications can be achieved by using intermediate partial specifications like this:

> [**D10**?=] The Widget has a Combination Lock [=>**R5**].
>
>   * [**D101**?=] The lock has a combination that is difficult to guess. [=>**D10**]
>   * [**D102**?=] The lock detects repeated attempts to gutess the combination. [=>**D10**]
>   * [**D103**?=] The lock is difficult to break without special tools. [=>**D10**]
>
> [**D1001**:=] The lock has at least 1000 combinations. [=>**D101**]
>
> [**D1002**:=] The lock is tamper proof to standard XXXXXX. [=>**D103**]


Now the system will not consider the design to be complete because **D102** is not covered by a more detailed specification.

# Markdown Integration

When the notation is used in a Markdown document, the special `@req` link target can be used to create links to the trace matrix. e.g.

```
[D10?=](@req) The Widget has a Combination Lock [=>R5](@req).
```

The `[D10?=]` link or the `[=>R5]` link will take the reader to the relevant row in the trace matrix.

<a id="foo"/>[RXXX](@req)

    extract_tags(string)

Extract requirements tracing tags from `string`.
