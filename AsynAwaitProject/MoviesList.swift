import SwiftUI

enum MovieListError: Error {
case failed
}

struct MoviesResponse: Decodable {
    let page: Int
    let results: [Movie]
}

struct Movie: Decodable, Identifiable {
    let id = UUID().uuidString
    let title: String
}

@Observable
class MoviesListViewModel {
    var loadingState: LoadingState<[Movie]> = .idle

    func fetchMovies() async {
        self.loadingState = .loading
        var request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1")!)
        request.addValue(token, forHTTPHeaderField: "Authorization")

        do {
            let task: (data: Data, response: URLResponse) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MoviesResponse.self, from: task.data)
            self.loadingState = .loaded(response.results)

        } catch {
            self.loadingState = .failure
        }


//        URLSession.shared.dataTask(with: request) { data, _, error in
//            if let error {
//                return .failure(.failed)
//            }
//
//            guard let unwrappedData = data else {
//                return
//            }
//
//            do {
//                let response = try JSONDecoder().decode(MoviesResponse.self, from: unwrappedData)
//                return .success(response.results)
//                self.loadingState = .loaded(response.results)
//            } catch {
//                return .failure(.failed)
//            }
//        }
//        .resume()
    }
}

enum LoadingState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failure
}

struct MoviesList: View {
    @State var viewModel = MoviesListViewModel()

    var body: some View {
        Group {
            switch self.viewModel.loadingState {
            case .idle:
                Color.red
            case .loading:
                Text("Loading...")
            case .loaded(let movies):
                List(movies) { movie in
                    NavigationLink(destination: {
                        Text("x")
                    }, label: {
                        Text(movie.title)
                    })
                }
            case .failure:
                Text("Error")
            }
        }
        .task {
            await self.viewModel.fetchMovies()
        }
    }
}

#Preview {
    MoviesList()
}
