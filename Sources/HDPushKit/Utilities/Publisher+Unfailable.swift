import Combine
import Foundation

public extension Publisher {
    // AnyPublisher<Output, Failure> -> AnyPublisher<Result<Output, Failure>, Never>
    func unfailable() -> AnyPublisher<Result<Output, Failure>, Never> {
        map { output -> Result<Output, Failure> in
                .success(output)
        }
        .catch { error -> Just<Result<Output, Failure>> in
            Just(.failure(error))
        }
        .eraseToAnyPublisher()
    }
}
