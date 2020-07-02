functor Problem (Grader : GRADER) :> PROBLEM =
  struct
    type t = {
      root      : Filename.t,
      grader    : Grader.t Remote.t,
      files     : Filename.t list,
      libraries : Library.t list
    }

    val op / = OS.Path.concat
    val load = fn path => Remote.hide {
      path = path,
      get = fn path => (
        case JSONParser.parseFile (path / "problem.json") of
          JSON.OBJECT [
            ("files"    , files    ),
            ("libraries", libraries)
          ] => {
            root = path,
            grader = Grader.load (path / "grader"),
            files = JSONUtil.arrayMap JSONUtil.asString files,
            libraries = JSONUtil.arrayMap JSONUtil.asString libraries
          }
        | _ => raise Fail ("Invalid problem at " ^ path)
      )
    }

    local
      datatype number = datatype LaTeX.number
      datatype latex = datatype LaTeX.t
      val makeSwitch =
        List.foldri
          (fn (i,(name,score),acc) =>
            IfNum (
              (Counter "task",EQUAL,Constant (i + 1)),  (* check if task counter (one-indexed) matches *)
              NewLine (
                IfStrEqual (  (* cross-validate label in writeup with expected label *)
                  ("#1",name),
                  Text (Grader.Score.toString score),
                  Error (Concat (Text ("Invalid placement of task: " ^ name ^ " at "), GetCounter "task"))
                )
              ),
              acc
            )
          )
          (Error (Text "Writeup contains more tasks than were expected"))
        o Grader.tasks
    in
      val writeup = fn problem : t => fn codepath => LaTeX.toString (
        List.foldMapr Concat NewLine (Text "") [
          Def ("codepath","",Text codepath),  (* set \codepath, used by \path{} *)
          Def ("taskscore","#1",makeSwitch (Remote.! (#grader problem))),
          Import (#root problem ^ "/writeup/","writeup"),
          ClearPage,
          StepCounter "problem",
          IfNum (  (* guarantee each problem uses exactly one section, so taskscore switch works *)
            (Counter "problem",EQUAL,Counter "section"),
            Text "",
            Error (Text ("Problem used multiple sections: " ^ #root problem))
          )
        ]
      ) ^ "\n"
    end

    val handout = fn problem : t => fn location => #libraries problem before (
      case List.null (#files problem) of
        false => FileUtils.copyTree (#root problem / "code", location)
      | true  => ()
    )

    val grader = fn problem : t => fn location =>
      Grader.stage (Remote.! (#grader problem)) location @ #libraries problem
  end
