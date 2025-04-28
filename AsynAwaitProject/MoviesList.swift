import SwiftUI

enum MovieListError: Error {
case failed
}

struct MoviesResponse: Decodable {
    let page: Int
    let results: [Movie]
}

struct Movie: Decodable {
    let title: String
}
/*
 curl --request GET \
 --url 'https://api.themoviedb.org/3/movie/popular?language=en-US&page=1' \
 --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTQxY2Q4NmMyYzI0MzBjNjZkZTZlNjdiZmZlOWM4NiIsIm5iZiI6MTU0ODcxNjYyOS4wMDQ5OTk5LCJzdWIiOiI1YzRmOGE1NTBlMGEyNjQ5NjVkOGM1NjUiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.IchHHp5mxpR2Uf6_1RadIs5JQMwo0RZfkVHNc8rIkuA' \
 --header 'accept: application/json'
 */

private let token = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OTQxY2Q4NmMyYzI0MzBjNjZkZTZlNjdiZmZlOWM4NiIsIm5iZiI6MTU0ODcxNjYyOS4wMDQ5OTk5LCJzdWIiOiI1YzRmOGE1NTBlMGEyNjQ5NjVkOGM1NjUiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.IchHHp5mxpR2Uf6_1RadIs5JQMwo0RZfkVHNc8rIkuA"


@Observable
class MoviesListViewModel {
    func fetchMovies(completion: @escaping (Result<[Movie], MovieListError>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.themoviedb.org/3/movie/popular?language=en-US&page=1")!)
        request.addValue(token, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(.failed))
            }

            guard let unwrappedData = data else {
                return
            }

            do {
                let response = try JSONDecoder().decode(MoviesResponse.self, from: unwrappedData)
                completion(.success(response.results))
            } catch {
                completion(.failure(.failed))
            }

        }
        .resume()
    }
}

struct MoviesList: View {
    @State var viewModel = MoviesListViewModel()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            self.viewModel.fetchMovies(completion: { movies in
                print(movies)
            })
        }
    }
}

#Preview {
    MoviesList()
}
