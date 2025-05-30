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
    let poster: String

    enum CodingKeys: String, CodingKey {
        case title
        case poster = "poster_path"
    }
}

private let token = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTQxY2Q4NmMyYzI0MzBjNjZkZTZlNjdiZmZlOWM4NiIsIm5iZiI6MTU0ODcxNjYyOS4wMDQ5OTk5LCJzdWIiOiI1YzRmOGE1NTBlMGEyNjQ5NjVkOGM1NjUiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.IchHHp5mxpR2Uf6_1RadIs5JQMwo0RZfkVHNc8rIkuA"

@Observable
class MoviesListViewModel {
    var loadingState: LoadingState<[Movie]> = .idle
    var imageCache: Data?

    func fetchImage(path: String) async {
        var request = URLRequest(url: URL(string: "https://image.tmdb.org/t/p/w500/Y6pjszkKQUZ5uBbiGg7KWiCksJ.jpg")!)
//        request.addValue(token, forHTTPHeaderField: "Authorization")

        do {
            let task: (data: Data, response: URLResponse) = try await URLSession.shared.data(for: request)
            self.imageCache = task.data
//            self.imageCache[path] = task.data
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }

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
                    .task {
                        await self.viewModel.fetchMovies()
                    }
            case .loading:
                Text("Loading...")
            case .loaded(let movies):
                List(movies) { movie in
                    NavigationLink(destination: {
                        Text("x")
                    }, label: {
                        if let data = self.viewModel.imageCache, let image = UIImage(data: data) {
                            Image(uiImage: image)
                        } else {
//                            Color.clear
//                                .task {
//                                    await self.viewModel.fetchImage(path: movie.poster)
//                                }
                        }
                    })
                    .task {
                        await self.viewModel.fetchImage(path: movie.poster)
                    }
                }
            case .failure:
                Text("Error")
            }
        }

    }
}

#Preview {
    MoviesList()
}
