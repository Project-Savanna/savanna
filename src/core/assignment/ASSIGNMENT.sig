signature ASSIGNMENT =
  sig
    structure Kind : KIND

    include CONFIG where type t = {
      name     : string,
      title    : string,
      kind     : Kind.t,
      problems : Problem.t Remote.t list,
      dates    : {
        out : Date.date,
        due : Date.date
      }
    }

    val stage : t * Filename.t -> unit
  end
