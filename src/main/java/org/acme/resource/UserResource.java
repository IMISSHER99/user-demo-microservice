package org.acme.resource;

import io.quarkus.hibernate.reactive.panache.Panache;
import io.smallrye.mutiny.Uni;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;
import org.acme.entity.UserDetails;

import java.util.List;

import static org.jboss.resteasy.reactive.RestResponse.Status.CREATED;

@Path("/users")
@ApplicationScoped
public class UserResource {

    @POST()
    @Path("/register")
    public Uni<Response> registerUser(UserDetails userDetails) {
        return Panache.withTransaction(userDetails::persist)
                .replaceWith(Response.ok(userDetails).status(CREATED)::build);
    }

    @GET()
    @Path("/list")
    public Uni<List<UserDetails>> listUsers() {
        return UserDetails.listAll();
    }

}
