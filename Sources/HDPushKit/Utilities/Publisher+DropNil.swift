import Foundation
import Combine

public extension Publisher {
    func dropNil<T>() -> AnyPublisher<T,Failure> where Output == T? {
        compactMap{$0}.eraseToAnyPublisher()
    }
}
