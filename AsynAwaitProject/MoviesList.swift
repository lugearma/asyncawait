import SwiftUI
import Foundation

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

class ImageCache {
//    var imageCache: [String: Data] = [:]
    private var imageCache = NSCache<NSString, NSData>()

    func fetchImage(path: String) async {
        let request = URLRequest(url: URL(string: "https://image.tmdb.org/t/p/w500\(path)")!)

        do {
            let task: (data: Data, response: URLResponse) = try await URLSession.shared.data(for: request)
            self.imageCache.setObject(NSData(data: task.data), forKey: NSString(string: path))
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
}

@Observable
class MoviesListViewModel {
    var loadingState: LoadingState<[Movie]> = .idle
    var imageCache: ImageCache

    init(imageCache: ImageCache) {
        self.loadingState = loadingState
        self.imageCache = imageCache
    }

    func fetchMovies() async {
        self.loadingState = .loading
        var request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1")!)
        request.addValue(token, forHTTPHeaderField: "Authorization")

        do {
            let task: (data: Data, response: URLResponse) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(MoviesResponse.self, from: task.data)

            await withTaskGroup(of: Void.self) { group in
                for poster in response.results.map(\.poster) {
                    group.addTask {
                        await self.imageCache.fetchImage(path: poster)
                    }
                }
            }

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
    @ObservedObject var viewModel: MoviesListViewModel

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
                        if let data = self.viewModel.imageCache[movie.poster], let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        }
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
