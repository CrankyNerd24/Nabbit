import Foundation

/// The screens pushed after the first tap on Home.
enum CaptureStep: Hashable {
    case thing(Verb)
    case when(Verb, thing: String)
}
